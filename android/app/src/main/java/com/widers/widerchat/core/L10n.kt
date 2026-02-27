package com.widers.widerchat.core

import com.widers.widerchat.domain.model.AppLocale

enum class TextKey {
    APP_NAME,
    APP_TAGLINE,
    LOGIN_TITLE,
    LOGIN_SUBTITLE,
    EMAIL_LABEL,
    EMAIL_PLACEHOLDER,
    PASSWORD_LABEL,
    PASSWORD_PLACEHOLDER,
    LOGIN_BUTTON,
    FORGOT_PASSWORD,
    LOGIN_ERROR,
    CHATS,
    SETTINGS,
    CONVERSATIONS_TITLE,
    SEARCH_PLACEHOLDER,
    ALL,
    OPEN,
    CLOSED,
    UNREAD,
    NO_CONVERSATIONS,
    NO_CONVERSATIONS_DESC,
    TYPE_MESSAGE,
    SEND,
    INTERNAL_NOTE,
    INTERNAL_NOTE_PLACEHOLDER,
    ADD_NOTE,
    CLOSE_CONVERSATION,
    REOPEN_CONVERSATION,
    CONVERSATION_CLOSED,
    ONLINE,
    LAST_SEEN,
    PRIVACY_POLICY,
    TERMS_OF_SERVICE,
    VERSION,
    LOGOUT,
    LOGOUT_CONFIRM,
    CANCEL,
    CONFIRM,
    PUSH_NOTIFICATIONS,
    SOUND_ALERTS,
    DARK_MODE,
    LANGUAGE,
    ENGLISH,
    ARABIC,
    ACCOUNT,
    APPEARANCE,
    NOTIFICATION_SETTINGS,
    ABOUT,
    TODAY,
    NEW_CONVERSATION_TITLE,
    NEW_CONVERSATION_MESSAGE,
    NAME_LABEL,
    PHONE_LABEL,
    CREATE,
    CAMERA,
    GALLERY,
    DOCUMENT,
    AUDIO,
    STOP_SEND_VOICE
}

fun tr(locale: AppLocale, key: TextKey): String {
    val isAr = locale == AppLocale.AR
    return when (key) {
        TextKey.APP_NAME -> if (isAr) "وايدرز" else "Widers"
        TextKey.APP_TAGLINE -> if (isAr) "واجهة واتساب للأعمال السحابية" else "WhatsApp Business Cloud API"
        TextKey.LOGIN_TITLE -> if (isAr) "مرحباً بعودتك" else "Welcome Back"
        TextKey.LOGIN_SUBTITLE -> if (isAr) "سجّل الدخول لإدارة محادثاتك" else "Sign in to manage your conversations"
        TextKey.EMAIL_LABEL -> if (isAr) "البريد الإلكتروني" else "Email Address"
        TextKey.EMAIL_PLACEHOLDER -> if (isAr) "أدخل بريدك الإلكتروني" else "Enter your email"
        TextKey.PASSWORD_LABEL -> if (isAr) "كلمة المرور" else "Password"
        TextKey.PASSWORD_PLACEHOLDER -> if (isAr) "أدخل كلمة المرور" else "Enter your password"
        TextKey.LOGIN_BUTTON -> if (isAr) "تسجيل الدخول" else "Sign In"
        TextKey.FORGOT_PASSWORD -> if (isAr) "نسيت كلمة المرور؟" else "Forgot password?"
        TextKey.LOGIN_ERROR -> if (isAr) "البريد الإلكتروني أو كلمة المرور غير صحيحة" else "Invalid email or password"
        TextKey.CHATS -> if (isAr) "الدردشات" else "Chats"
        TextKey.SETTINGS -> if (isAr) "الإعدادات" else "Settings"
        TextKey.CONVERSATIONS_TITLE -> if (isAr) "المحادثات" else "Conversations"
        TextKey.SEARCH_PLACEHOLDER -> if (isAr) "البحث في المحادثات..." else "Search conversations..."
        TextKey.ALL -> if (isAr) "الكل" else "All"
        TextKey.OPEN -> if (isAr) "مفتوحة" else "Open"
        TextKey.CLOSED -> if (isAr) "مغلقة" else "Closed"
        TextKey.UNREAD -> if (isAr) "غير مقروءة" else "unread"
        TextKey.NO_CONVERSATIONS -> if (isAr) "لا توجد محادثات بعد" else "No conversations yet"
        TextKey.NO_CONVERSATIONS_DESC -> if (isAr) "عندما يراسلك العملاء، ستظهر المحادثات هنا." else "When customers message you, conversations will appear here."
        TextKey.TYPE_MESSAGE -> if (isAr) "اكتب رسالة..." else "Type a message..."
        TextKey.SEND -> if (isAr) "إرسال" else "Send"
        TextKey.INTERNAL_NOTE -> if (isAr) "ملاحظة داخلية" else "Internal Note"
        TextKey.INTERNAL_NOTE_PLACEHOLDER -> if (isAr) "اكتب ملاحظة (غير مرئية للعميل)..." else "Write a note (not visible to customer)..."
        TextKey.ADD_NOTE -> if (isAr) "إضافة ملاحظة" else "Add Note"
        TextKey.CLOSE_CONVERSATION -> if (isAr) "إغلاق المحادثة" else "Close Conversation"
        TextKey.REOPEN_CONVERSATION -> if (isAr) "إعادة فتح المحادثة" else "Reopen Conversation"
        TextKey.CONVERSATION_CLOSED -> if (isAr) "تم إغلاق المحادثة" else "Conversation closed"
        TextKey.ONLINE -> if (isAr) "متصل" else "Online"
        TextKey.LAST_SEEN -> if (isAr) "آخر ظهور" else "Last seen"
        TextKey.PRIVACY_POLICY -> if (isAr) "سياسة الخصوصية" else "Privacy Policy"
        TextKey.TERMS_OF_SERVICE -> if (isAr) "شروط الخدمة" else "Terms of Service"
        TextKey.VERSION -> if (isAr) "الإصدار" else "Version"
        TextKey.LOGOUT -> if (isAr) "تسجيل الخروج" else "Sign Out"
        TextKey.LOGOUT_CONFIRM -> if (isAr) "هل أنت متأكد أنك تريد تسجيل الخروج؟" else "Are you sure you want to sign out?"
        TextKey.CANCEL -> if (isAr) "إلغاء" else "Cancel"
        TextKey.CONFIRM -> if (isAr) "تأكيد" else "Confirm"
        TextKey.PUSH_NOTIFICATIONS -> if (isAr) "إشعارات الدفع" else "Push Notifications"
        TextKey.SOUND_ALERTS -> if (isAr) "التنبيهات الصوتية" else "Sound Alerts"
        TextKey.DARK_MODE -> if (isAr) "الوضع الداكن" else "Dark Mode"
        TextKey.LANGUAGE -> if (isAr) "اللغة" else "Language"
        TextKey.ENGLISH -> if (isAr) "الإنجليزية" else "English"
        TextKey.ARABIC -> if (isAr) "العربية" else "Arabic"
        TextKey.ACCOUNT -> if (isAr) "الحساب" else "Account"
        TextKey.APPEARANCE -> if (isAr) "المظهر" else "Appearance"
        TextKey.NOTIFICATION_SETTINGS -> if (isAr) "إعدادات الإشعارات" else "Notification Settings"
        TextKey.ABOUT -> if (isAr) "حول" else "About"
        TextKey.TODAY -> if (isAr) "اليوم" else "Today"
        TextKey.NEW_CONVERSATION_TITLE -> if (isAr) "محادثة جديدة" else "New conversation"
        TextKey.NEW_CONVERSATION_MESSAGE -> if (isAr) "أنشئ جهة اتصال وافتح محادثتها." else "Create a contact and open its chat."
        TextKey.NAME_LABEL -> if (isAr) "الاسم" else "Name"
        TextKey.PHONE_LABEL -> if (isAr) "الهاتف" else "Phone"
        TextKey.CREATE -> if (isAr) "إنشاء" else "Create"
        TextKey.CAMERA -> if (isAr) "الكاميرا" else "Camera"
        TextKey.GALLERY -> if (isAr) "المعرض" else "Gallery"
        TextKey.DOCUMENT -> if (isAr) "مستند" else "Document"
        TextKey.AUDIO -> if (isAr) "صوت" else "Audio"
        TextKey.STOP_SEND_VOICE -> if (isAr) "إيقاف وإرسال الصوت" else "Stop & send voice"
    }
}
