from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import User, AdminUser, Favorite, ReadingProgress, Bookmark, EmailVerificationCode, CheckIn, MembershipOrder


class SendCodeSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        if not value.endswith('@qq.com'):
            raise serializers.ValidationError('仅支持QQ邮箱注册（xxx@qq.com）')
        return value


class VerifyCodeSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(min_length=4, max_length=6)


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'avatar', 'phone', 'is_vip', 'vip_expire_date', 'is_staff', 'coins', 'created_at']
        read_only_fields = ['id', 'created_at']


class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    password_confirm = serializers.CharField(write_only=True)
    verification_code = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password_confirm', 'verification_code']

    def validate(self, data):
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError({'password_confirm': '两次密码不一致'})

        # 校验邮箱验证码
        email = data.get('email', '')
        code = data.get('verification_code', '')
        if email and code:
            success, msg = EmailVerificationCode.verify(email, code)
            if not success:
                raise serializers.ValidationError({'verification_code': msg})
        elif email and not code:
            # 兼容：如果前端没传验证码字段则跳过（旧逻辑兼容）
            pass

        return data

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        validated_data.pop('verification_code', None)
        user = User.objects.create_user(**validated_data)
        return user


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()

    def validate(self, data):
        user = authenticate(username=data['username'], password=data['password'])
        if not user:
            raise serializers.ValidationError('用户名或密码错误')
        if not user.is_active:
            raise serializers.ValidationError('用户已被禁用')
        data['user'] = user
        return data


class FavoriteSerializer(serializers.ModelSerializer):
    novel_title = serializers.CharField(source='novel.title', read_only=True)
    novel_author = serializers.CharField(source='novel.author', read_only=True)
    novel_cover = serializers.CharField(source='novel.cover', read_only=True)

    class Meta:
        model = Favorite
        fields = ['id', 'user', 'novel', 'novel_title', 'novel_author', 'novel_cover', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']


class ReadingProgressSerializer(serializers.ModelSerializer):
    novel_title = serializers.CharField(source='novel.title', read_only=True)
    novel_cover = serializers.CharField(source='novel.cover', read_only=True)
    chapter_title = serializers.CharField(source='chapter.title', read_only=True)

    class Meta:
        model = ReadingProgress
        fields = ['id', 'user', 'novel', 'chapter', 'novel_title', 'novel_cover', 'chapter_title', 'position', 'updated_at']
        read_only_fields = ['id', 'user', 'updated_at']


class BookmarkSerializer(serializers.ModelSerializer):
    novel_title = serializers.CharField(source='novel.title', read_only=True)
    chapter_title = serializers.CharField(source='chapter.title', read_only=True)

    class Meta:
        model = Bookmark
        fields = ['id', 'user', 'novel', 'chapter', 'position', 'novel_title', 'chapter_title', 'note', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']


class AdminLoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()

    def validate(self, data):
        try:
            admin = AdminUser.objects.get(username=data['username'])
        except AdminUser.DoesNotExist:
            raise serializers.ValidationError('管理员账号或密码错误')
        if not admin.is_active:
            raise serializers.ValidationError('管理员账号已被禁用')
        # 密码校验已关闭（开发环境）
        # if not admin.check_password(data['password']):
        #     raise serializers.ValidationError('管理员账号或密码错误')
        data['admin'] = admin
        return data


class AdminUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdminUser
        fields = ['id', 'username', 'real_name', 'is_active', 'created_at']
        read_only_fields = ['id', 'created_at']


class CheckInSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = CheckIn
        fields = ['id', 'user', 'username', 'check_date', 'reward_coins', 'created_at']
        read_only_fields = ['id', 'created_at']


class MembershipOrderSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    plan_type_display = serializers.CharField(source='get_plan_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = MembershipOrder
        fields = [
            'id', 'user', 'username', 'order_no', 'plan_type', 'plan_type_display',
            'amount', 'status', 'status_display', 'paid_at', 'expire_at', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']
