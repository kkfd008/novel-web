import os, sys, time, re, json, random, logging, urllib.request
from datetime import datetime
from lxml import etree

try:
    import sqlite3
    HAS_SQLITE3 = True
except ImportError:
    HAS_SQLITE3 = False

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    datefmt='%H:%M:%S'
)
log = logging.getLogger('InkCrawler')

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

DB_PATH = os.path.join(BASE_DIR, 'db.sqlite3')

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
}

COVER_DIR = os.path.join(BASE_DIR, 'media', 'covers')

CAT_MAP = {
    '/xuanhuanxiaoshuo/': ('玄幻', 1),
    '/xiuzhenxiaoshuo/': ('修真', 1),
    '/dushixiaoshuo/': ('都市', 2),
    '/chuanyuexiaoshuo/': ('穿越', 3),
    '/wangyouxiaoshuo/': ('游戏', 4),
    '/kehuanxiaoshuo/': ('科幻', 5),
    '/wuxiaxiaoshuo/': ('武侠', 6),
    '/xuanyixiaoshuo/': ('悬疑', 7),
    '/lishixiaoshuo/': ('历史', 8),
}


class XbiqugeCrawler:

    BASE = 'https://www.xbiquge.la'

    def __init__(self, db_path=None):
        self.db_path = db_path or DB_PATH
        self.conn = None
        self.stats = {'novels': 0, 'chapters': 0, 'errors': 0}
        self.session = requests.Session()
        self.session.headers.update(HEADERS)
        for k in ['HTTP_PROXY','HTTPS_PROXY','http_proxy','https_proxy','ALL_PROXY','all_proxy']:
            os.environ[k] = ''
        self.session.trust_env = False

        if not os.path.exists(COVER_DIR):
            os.makedirs(COVER_DIR)

    def connect_db(self):
        if not HAS_SQLITE3:
            log.warning('sqlite3 not available, using dry-run mode')
            return False
        try:
            self.conn = sqlite3.connect(self.db_path)
            self.conn.row_factory = sqlite3.Row
            log.info(f"SQLite OK: {self.db_path}")
            return True
        except Exception as e:
            log.error(f"DB error: {e}")
            return False

    def close(self):
        if self.conn:
            self.conn.close()

    def get(self, url, encoding='utf-8', retries=3):
        full = url if url.startswith('http') else self.BASE + url
        for i in range(retries):
            try:
                r = self.session.get(full, timeout=25)
                r.encoding = encoding
                if r.status_code == 200:
                    return etree.HTML(r.text)
                log.warning(f"HTTP {r.status_code}: {full}")
            except Exception as e:
                if i < retries - 1:
                    time.sleep(2 * (i + 1))
                else:
                    log.error(f"Failed {full}: {e}")
        return None

    def clean_text(self, text):
        text = re.sub(r'\s+', '', text)
        text = text.replace('\xa0', '').replace('\u3000', '')
        text = re.sub(r'www\.[a-z]+\.(com|net|cn|org)[^\n]*', '', text)
        text = re.sub(r'[（(]\s*本章完\s*[）)]', '', text)
        text = re.sub(r'(一秒记住|请收藏|免费阅读|更新最快|笔趣阁|全本小说网|看书网|香书小说)[^\n]{0,60}', '', text)
        return text.strip()

    def download_cover(self, img_url, title):
        if not img_url:
            return '/media/covers/default.jpg'
        try:
            ext = img_url.split('.')[-1].split('?')[0][:4]
            if ext not in ('jpg','jpeg','png','webp'):
                ext = 'jpg'
            fname = f"{title[:20]}.{ext}"
            fpath = os.path.join(COVER_DIR, fname)
            req = urllib.request.Request(img_url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = resp.read()
                if len(data) > 1000:
                    with open(fpath, 'wb') as f:
                        f.write(data)
                    return f'/media/covers/{fname}'
        except Exception as e:
            log.debug(f"Cover fail [{title}]: {e}")
        return '/media/covers/default.jpg'

    def get_categories(self):
        cats = [
            {'name': '玄幻', 'url': '/xuanhuanxiaoshuo/'},
            {'name': '修真', 'url': '/xiuzhenxiaoshuo/'},
            {'name': '都市', 'url': '/dushixiaoshuo/'},
            {'name': '穿越', 'url': '/chuanyuexiaoshuo/'},
            {'name': '网游', 'url': '/wangyouxiaoshuo/'},
            {'name': '科幻', 'url': '/kehuanxiaoshuo/'},
            {'name': '武侠', 'url': '/wuxiaxiaoshuo/'},
            {'name': '悬疑', 'url': '/xuanyixiaoshuo/'},
            {'name': '历史', 'url': '/lishixiaoshuo/'},
        ]
        log.info(f"Categories: {len(cats)} (predefined)")
        return cats

    CAT_ID_MAP = {
        '/xuanhuanxiaoshuo/': '1',
        '/xiuzhenxiaoshuo/': '1',
        '/dushixiaoshuo/': '3',
        '/chuanyuexiaoshuo/': '4',
        '/wangyouxiaoshuo/': '5',
        '/kehuanxiaoshuo/': '6',
        '/wuxiaxiaoshuo/': '7',
        '/xuanyixiaoshuo/': '1',
        '/lishixiaoshuo/': '2',
    }

    def get_book_list(self, cat_url, max_pages=3):
        books = []
        seen = set()

        cat_id = self.CAT_ID_MAP.get(cat_url, '1')

        for page in range(1, max_pages + 1):
            url = f"/fenlei/{cat_id}_{page}.html"
            html = self.get(url)
            if not html:
                continue
            for a in html.xpath("//div[@class='l']//a"):
                href = a.get('href', '')
                title = ''.join(a.itertext()).strip()
                if (href and title and '.html' not in href
                        and '/fenlei/' not in href and len(title) > 2
                        and href not in seen):
                    seen.add(href)
                    books.append({'title': title, 'url': href})
            time.sleep(random.uniform(0.5, 1.2))

        log.info(f"Books found: {len(books)}")
        return books

    def parse_book_detail(self, book_info):
        url = book_info.get('url', '')
        html = self.get(url)
        if not html:
            return None

        title = ''.join(html.xpath("//h1/text()")).strip() or book_info.get('title', '')

        info_p = html.xpath("//div[@id='info']//p")
        author = ''
        status_val = 0
        intro = ''
        cover_url = ''
        category = '玄幻'
        tags = ''

        for p in info_p:
            txt = ''.join(p.itertext()).strip()
            if '作者' in txt:
                m = re.search(r'作者[：:]\s*(.+)', txt)
                if m:
                    author = m.group(1).strip()
            if '类别' in txt or '分类' in txt:
                for k, v in CAT_MAP.items():
                    if k in txt:
                        category, _ = v
                        break
            if '状态' in txt:
                if '完结' in txt or '完成' in txt:
                    status_val = 1

        intro_nodes = html.xpath("//div[@id='intro']//text()")
        intro = '\n'.join(n.strip() for n in intro_nodes if n.strip())[:2000]

        img_node = html.xpath("//div[@id='fmimg']//img/@src")
        if img_node:
            cover_url = img_node[0]
            if not cover_url.startswith('http'):
                cover_url = self.BASE + cover_url

        tag_nodes = html.xpath("//div[@id='info']//p[contains(.,'标签')]//text()")
        if tag_nodes:
            tags = ','.join(t.strip() for t in tag_nodes if t.strip() and '标签' not in t)[:200]

        chap_links = html.xpath("//dd/a")

        chapters = []
        for idx, a in enumerate(chap_links):
            ch_title = ''.join(a.itertext()).strip()
            ch_href = a.get('href', '')
            if ch_title and ch_href:
                chapters.append({
                    'title': ch_title,
                    'url': ch_href,
                    'order': idx + 1,
                })
                if len(chapters) >= 10:
                    break

        wc_match = re.search(r'(\d+)', ''.join(html.xpath("//div[@id='info']//p[contains(.,'字')]//text()")))
        word_count = int(wc_match.group(1)) if wc_match else 0

        return {
            'title': title,
            'author': author or '未知作者',
            'description': intro,
            'category': category,
            'tags': tags or category,
            'status': status_val,
            'word_count': word_count,
            'cover': self.download_cover(cover_url, title),
            'chapters': chapters,
        }

    def parse_chapter_content(self, ch):
        url = ch.get('url', '')
        html = self.get(url)
        if not html:
            return ''
        texts = html.xpath("//div[@id='content']//text()")
        content = self.clean_text(''.join(texts))
        ch['word_count'] = len(content)
        return content

    def insert_novel(self, book):
        if not self.conn:
            return None
        cur = self.conn.cursor()
        cur.execute("SELECT id FROM novel WHERE title=? LIMIT 1", (book['title'],))
        row = cur.fetchone()
        if row:
            log.info(f"  EXISTS: {book['title']} (id={row[0]})")
            return row[0]

        cur.execute("""INSERT INTO novel (title,author,cover,description,category,tags,
                    status,audit_status,word_count,view_count,recommend,
                    created_at,updated_at)
                  VALUES (?,?,?,?,?,?,?,?,?,?,?,datetime('now'),datetime('now'))""",
                   (book['title'], book['author'], book['cover'],
                    book['description'], book['category'], book['tags'],
                    book['status'], 2, book['word_count'], 0, 0))
        self.conn.commit()
        nid = cur.lastrowid
        self.stats['novels'] += 1
        log.info(f"  INSERT novel id={nid}: {book['title']}")
        return nid

    def insert_chapter(self, nid, ch, content):
        if not self.conn or len(content) < 30:
            return
        cur = self.conn.cursor()
        cur.execute("""SELECT id FROM chapter WHERE novel_id=? AND title=? LIMIT 1""",
                   (nid, ch['title']))
        if cur.fetchone():
            return
        cur.execute("""INSERT INTO chapter (novel_id,title,content,chapter_order,
                    word_count,publish_status,created_at,updated_at)
                  VALUES (?,?,?,?,?,1,datetime('now'),datetime('now'))""",
                   (nid, ch['title'], content, ch['order'], ch.get('word_count', 0)))
        self.conn.commit()
        self.stats['chapters'] += 1

    def crawl_single_book(self, detail_url):
        log.info(f"Crawling: {detail_url}")
        book = self.parse_book_detail({'url': detail_url})
        if not book:
            return
        nid = self.insert_novel(book)
        total = len(book.get('chapters', []))
        for idx, ch in enumerate(book['chapters']):
            try:
                content = self.parse_chapter_content(ch)
                if content and len(content) > 50:
                    self.insert_chapter(nid, ch, content)
                    log.info(f"    [{idx+1}/{total}] {ch['title']} ({len(content)}字)")
                else:
                    log.warning(f"    [{idx+1}/{total}] SKIP short: {ch['title']}")
                time.sleep(random.uniform(0.3, 0.7))
            except Exception as e:
                self.stats['errors'] += 1
                log.error(f"    Chapter ERR {ch['title']}: {e}")
        log.info(f"  DONE: {book['title']} -> {self.stats['chapters']} chapters")

    def crawl_category(self, cat_url, cat_name, max_books=3, max_pages=2):
        log.info(f"\n{'='*55}")
        log.info(f"Category: {cat_name} ({cat_url})")
        log.info(f"{'='*55}")

        books = self.get_book_list(cat_url, max_pages=max_pages)
        for bi in books[:max_books]:
            try:
                self.crawl_single_book(bi['url'])
            except Exception as e:
                self.stats['errors'] += 1
                log.error(f"Book ERR: {e}")
            time.sleep(random.uniform(1, 2.5))

    def crawl_all(self, max_cats=3, max_books=3, max_pages=2):
        start = time.time()
        cats = self.get_categories()
        for c in cats[:max_cats]:
            try:
                self.crawl_category(c['url'], c['name'],
                                   max_books=max_books, max_pages=max_pages)
            except Exception as e:
                self.stats['errors'] += 1
                log.error(f"Cat ERR [{c['name']}]: {e}")

        elapsed = time.time() - start
        log.info(f"\n{'='*55}")
        log.info(f"CRAWL COMPLETE ({elapsed:.0f}s)")
        log.info(f"  Novels : {self.stats['novels']}")
        log.info(f"  Chapters: {self.stats['chapters']}")
        log.info(f"  Errors : {self.stats['errors']}")
        log.info(f"{'='*55}")


def main():
    import argparse
    parser = argparse.ArgumentParser(description='InkFiction Novel Crawler')
    parser.add_argument('--mode', choices=['db', 'dry'], default='db')
    parser.add_argument('--url', type=str, default='', help='Single book URL to crawl')
    parser.add_argument('--cat-url', type=str, default='')
    parser.add_argument('--cats', type=int, default=3)
    parser.add_argument('--books', type=int, default=3)
    parser.add_argument('--pages', type=int, default=2)
    parser.add_argument('--max-chapters', type=int, default=10, help='Max chapters per book (default 10)')
    args = parser.parse_args()

    crawler = XbiqugeCrawler()

    if args.mode == 'db':
        if not crawler.connect_db():
            sys.exit(1)

    try:
        if args.url:
            crawler.crawl_single_book(args.url)
        elif args.cat_url:
            crawler.crawl_category(args.cat_url, 'Custom',
                                   max_books=args.books, max_pages=args.pages)
        else:
            crawler.crawl_all(max_cats=args.cats,
                             max_books=args.books, max_pages=args.pages)
    except KeyboardInterrupt:
        log.info("\nInterrupted by user")
    finally:
        crawler.close()


if __name__ == '__main__':
    import requests
    main()
