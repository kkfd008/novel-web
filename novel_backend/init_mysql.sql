-- ============================================================
--  墨香书阁 (InkFiction) — MySQL 建表脚本（已废弃）
--  项目已切换为 SQLite3，建表由 Django migrations 自动管理。
--  此文件仅保留作为历史参考。
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO';

-- ============================================================
--  1. 用户表 (user)
--  继承 Django AbstractUser，自定义字段: avatar/phone/is_vip/vip_expire_date/is_author/pen_name/bio
-- ============================================================
DROP TABLE IF EXISTS `user_user_permissions`;
DROP TABLE IF EXISTS `user_groups`;
DROP TABLE IF EXISTS `user`;

CREATE TABLE `user` (
    `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    `password`        VARCHAR(128) NOT NULL DEFAULT '' COMMENT '密码哈希',
    `last_login`      DATETIME(6) NULL DEFAULT NULL COMMENT '最后登录时间',
    `is_superuser`    TINYINT(1) NOT NULL DEFAULT 0 COMMENT '超级管理员',
    `username`        VARCHAR(150) NOT NULL COMMENT '用户名',
    `first_name`      VARCHAR(150) NOT NULL DEFAULT '' COMMENT '名',
    `last_name`       VARCHAR(150) NOT NULL DEFAULT '' COMMENT '姓',
    `email`           VARCHAR(254) NOT NULL DEFAULT '' COMMENT '邮箱',
    `is_staff`        TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否员工',
    `is_active`       TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否激活',
    `date_joined`     DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '注册时间',
    `avatar`          VARCHAR(255) NOT NULL DEFAULT '' COMMENT '头像URL',
    `phone`           VARCHAR(20) NOT NULL DEFAULT '' COMMENT '手机号',
    `is_vip`          TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否VIP会员',
    `vip_expire_date` DATETIME(6) NULL DEFAULT NULL COMMENT 'VIP到期时间',
    `is_author`       TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否作者',
    `pen_name`        VARCHAR(50) NOT NULL DEFAULT '' COMMENT '笔名',
    `bio`             VARCHAR(200) NOT NULL DEFAULT '' COMMENT '作者简介',
    `created_at`      DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `idx_user_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

CREATE TABLE `user_groups` (
    `id`        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`   INT UNSIGNED NOT NULL,
    `group_id`  INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_user_group` (`user_id`, `group_id`),
    KEY `fk_ug_user` (`user_id`),
    KEY `fk_ug_group` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_user_permissions` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`       INT UNSIGNED NOT NULL,
    `permission_id` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_user_perm` (`user_id`, `permission_id`),
    KEY `fk_uup_user` (`user_id`),
    KEY `fk_uup_perm` (`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
--  2. 小说表 (novel)
-- ============================================================
DROP TABLE IF EXISTS `comment`;
DROP TABLE IF EXISTS `bookmark`;
DROP TABLE IF EXISTS `reading_progress`;
DROP TABLE IF EXISTS `favorite`;
DROP TABLE IF EXISTS `chapter`;
DROP TABLE IF EXISTS `novel`;

CREATE TABLE `novel` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    `title`         VARCHAR(100) NOT NULL COMMENT '书名',
    `author`        VARCHAR(50) NOT NULL COMMENT '原作者名',
    `author_user_id`INT UNSIGNED NULL DEFAULT NULL COMMENT '作者账号ID(FK→user)',
    `cover`         VARCHAR(500) NOT NULL DEFAULT '' COMMENT '封面路径',
    `description`   LONGTEXT NOT NULL COMMENT '简介',
    `category`      VARCHAR(20) NOT NULL COMMENT '分类',
    `tags`          VARCHAR(200) NOT NULL DEFAULT '' COMMENT '标签(逗号分隔)',
    `status`        SMALLINT NOT NULL DEFAULT 0 COMMENT '连载状态:0连载中/1完结/2下架',
    `audit_status`  SMALLINT NOT NULL DEFAULT 2 COMMENT '审核状态:0草稿/1审核中/2已发布/3驳回',
    `word_count`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '总字数',
    `view_count`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '阅读量',
    `recommend`     INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '推荐票',
    `created_at`    DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '创建时间',
    `updated_at`    DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_novel_category` (`category`),
    KEY `idx_novel_status` (`status`),
    KEY `idx_novel_audit_status` (`audit_status`),
    KEY `idx_novel_author_user` (`author_user_id`),
    CONSTRAINT `fk_novel_author_user` FOREIGN KEY (`author_user_id`) REFERENCES `user`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='小说表';


-- ============================================================
--  3. 章节表 (chapter)
-- ============================================================
CREATE TABLE `chapter` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    `novel_id`      INT UNSIGNED NOT NULL COMMENT '所属小说ID(FK→novel)',
    `title`         VARCHAR(100) NOT NULL COMMENT '章节标题',
    `content`       LONGTEXT NOT NULL COMMENT '章节内容',
    `chapter_order` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '章节序号',
    `word_count`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '章节字数',
    `publish_status`SMALLINT NOT NULL DEFAULT 1 COMMENT '发布状态:0草稿/1已发布/2已下架',
    `created_at`    DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '创建时间',
    `updated_at`    DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_chapter_novel` (`novel_id`),
    KEY `idx_chapter_order` (`novel_id`, `chapter_order`),
    CONSTRAINT `fk_chapter_novel` FOREIGN KEY (`novel_id`) REFERENCES `novel`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='章节表';


-- ============================================================
--  4. 收藏表 (favorite)
--  唯一约束: user_id + novel_id
-- ============================================================
CREATE TABLE `favorite` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    `user_id`    INT UNSIGNED NOT NULL COMMENT '用户ID(FK→user)',
    `novel_id`   INT UNSIGNED NOT NULL COMMENT '小说ID(FK→novel)',
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '收藏时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_favorite_user_novel` (`user_id`, `novel_id`),
    KEY `idx_favorite_user` (`user_id`),
    KEY `idx_favorite_novel` (`novel_id`),
    CONSTRAINT `fk_favorite_user` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_favorite_novel` FOREIGN KEY (`novel_id`) REFERENCES `novel`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收藏表';


-- ============================================================
--  5. 阅读进度表 (reading_progress)
--  唯一约束: user_id + novel_id
-- ============================================================
CREATE TABLE `reading_progress` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    `user_id`     INT UNSIGNED NOT NULL COMMENT '用户ID(FK→user)',
    `novel_id`    INT UNSIGNED NOT NULL COMMENT '小说ID(FK→novel)',
    `chapter_id`  INT UNSIGNED NOT NULL COMMENT '当前章节ID(FK→chapter)',
    `position`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '阅读位置(%)',
    `updated_at`  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_progress_user_novel` (`user_id`, `novel_id`),
    KEY `idx_progress_user` (`user_id`),
    KEY `idx_progress_chapter` (`chapter_id`),
    CONSTRAINT `fk_rp_user` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_rp_novel` FOREIGN KEY (`novel_id`) REFERENCES `novel`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_rp_chapter` FOREIGN KEY (`chapter_id`) REFERENCES `chapter`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='阅读进度表';


-- ============================================================
--  6. 书签表 (bookmark)
-- ============================================================
CREATE TABLE `bookmark` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    `user_id`     INT UNSIGNED NOT NULL COMMENT '用户ID(FK→user)',
    `novel_id`    INT UNSIGNED NOT NULL COMMENT '小说ID(FK→novel)',
    `chapter_id`  INT UNSIGNED NOT NULL COMMENT '章节ID(FK→chapter)',
    `position`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '阅读位置(%)',
    `note`        VARCHAR(200) NOT NULL DEFAULT '' COMMENT '备注',
    `created_at`  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_bm_user` (`user_id`),
    KEY `idx_bm_novel` (`novel_id`),
    KEY `idx_bm_chapter` (`chapter_id`),
    CONSTRAINT `fk_bm_user` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_bm_novel` FOREIGN KEY (`novel_id`) REFERENCES `novel`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_bm_chapter` FOREIGN KEY (`chapter_id`) REFERENCES `chapter`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='书签表';


-- ============================================================
--  7. 评论表 (comment)
-- ============================================================
CREATE TABLE `comment` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    `novel_id`    INT UNSIGNED NOT NULL COMMENT '小说ID(FK→novel)',
    `user_id`     INT UNSIGNED NOT NULL COMMENT '用户ID(FK→user)',
    `content`     VARCHAR(500) NOT NULL COMMENT '评论内容',
    `rating`      TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '评分(0-5,0纯评论)',
    `created_at`  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '发表时间',
    PRIMARY KEY (`id`),
    KEY `idx_comment_novel` (`novel_id`),
    KEY `idx_comment_user` (`user_id`),
    KEY `idx_comment_rating` (`rating`),
    CONSTRAINT `fk_comment_novel` FOREIGN KEY (`novel_id`) REFERENCES `novel`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_comment_user` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评论表';


-- ============================================================
--  恢复外键检查 + 完成
-- ============================================================
SET FOREIGN_KEY_CHECKS = 1;

SELECT CONCAT('✓ 建表完成! 共创建 ', COUNT(*), ' 张表') AS result
FROM information_schema.tables
WHERE table_schema = 'novel_fiction' AND table_type = 'BASE TABLE';
