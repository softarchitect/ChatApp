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
    STOP_SEND_VOICE,
    CONTACT_INFO,
    STATUS,
    PRESENCE,
    MEDIA_LINKS_DOCS,
    MUTE,
    UNMUTE,
    DELETE,
    MEDIA_LINKS_DOCS_TITLE,
    CLOSE,
    NO_ITEMS_IN_TAB,
    PHOTO,
    VIDEO,
    LINK,
    UNAVAILABLE,
    NO_URL_FROM_BACKEND,
    UNABLE_TO_LOAD_AUDIO,
    MEDIA_TAB,
    DOCS_TAB,
    LINKS_TAB,
    TAP_TO_OPEN_IMAGE,
    OPEN_ACTION,
    FAILED_TO_LOAD_IMAGE,
    AUDIO_MESSAGE,
    MEDIA_MESSAGE,
    LOCATION,
    INTERNAL_NOTE_BADGE,
    YOU_LABEL,
    ASSIGN_AGENT,
    UNASSIGN_AGENT,
    MUTE_CONVERSATION,
    UNMUTE_CONVERSATION,
    MARK_AS_READ,
    MARK_AS_UNREAD,
    ATTACH_DETACH_TAG,
    SEND_TEMPLATE,
    SEND_FLOW,
    SEND_QUICK_REPLY,
    SYNC_CUSTOM_FIELD,
    UPDATE_CONTACT,
    DELETE_CHAT,
    ASSIGN_AGENT_TITLE,
    AGENT_ID,
    ATTACH_DETACH_TAG_TITLE,
    TAG_ID,
    ATTACH,
    DETACH,
    SEND_TEMPLATE_TITLE,
    TEMPLATE_ID,
    SEND_FLOW_TITLE,
    FLOW_ID,
    SEND_QUICK_REPLY_TITLE,
    SYNC_CUSTOM_FIELD_TITLE,
    FIELD_ID,
    FIELD_VALUE,
    SYNC,
    DELETE_CHAT_QUESTION,
    DELETE_CHAT_ENDPOINT_HINT,
    CALL_UNAVAILABLE,
    CALL_UNAVAILABLE_MESSAGE,
    OK,
    LAST_UPDATED,
    BACKEND_TOOLS,
    PROFILE,
    SYNC_SUPPORT_DATA,
    CREATE_UPDATE_TAG,
    TAG_NAME,
    TAG_COLOR_HEX,
    TAG_ID_OPTIONAL,
    SAVE,
    CREATE_UPDATE_REPLY,
    REPLY_NAME,
    REPLY_TEXT,
    REPLY_ID_OPTIONAL,
    ADD_CONTACT_TITLE,
    EMAIL_OPTIONAL,
    ADD,
    CANNOT_SHARE_UNAVAILABLE,
    CANNOT_DOWNLOAD_UNAVAILABLE,
    DOWNLOADING,
    UNABLE_TO_START_DOWNLOAD,
    SEARCH_CONTACTS,
    LOADING_CONTACTS,
    NOTE_BY,
    LOADING_IMAGE,
    POWERED_BY_WIDERS,
    META_APPROVED_PARTNER
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
        TextKey.CONTACT_INFO -> if (isAr) "معلومات جهة الاتصال" else "Contact info"
        TextKey.STATUS -> if (isAr) "الحالة" else "Status"
        TextKey.PRESENCE -> if (isAr) "التواجد" else "Presence"
        TextKey.MEDIA_LINKS_DOCS -> if (isAr) "الوسائط والروابط والمستندات" else "Media, links and docs"
        TextKey.MUTE -> if (isAr) "كتم" else "Mute"
        TextKey.UNMUTE -> if (isAr) "إلغاء الكتم" else "Unmute"
        TextKey.DELETE -> if (isAr) "حذف" else "Delete"
        TextKey.MEDIA_LINKS_DOCS_TITLE -> if (isAr) "الوسائط والروابط والمستندات" else "Media, links and docs"
        TextKey.CLOSE -> if (isAr) "إغلاق" else "Close"
        TextKey.NO_ITEMS_IN_TAB -> if (isAr) "لا توجد عناصر في هذا التبويب." else "No items in this tab."
        TextKey.PHOTO -> if (isAr) "صورة" else "Photo"
        TextKey.VIDEO -> if (isAr) "فيديو" else "Video"
        TextKey.LINK -> if (isAr) "رابط" else "Link"
        TextKey.UNAVAILABLE -> if (isAr) "غير متاح" else "Unavailable"
        TextKey.NO_URL_FROM_BACKEND -> if (isAr) "لا يوجد رابط من الخادم" else "No URL from backend"
        TextKey.UNABLE_TO_LOAD_AUDIO -> if (isAr) "تعذر تحميل الصوت." else "Unable to load audio."
        TextKey.MEDIA_TAB -> if (isAr) "وسائط" else "Media"
        TextKey.DOCS_TAB -> if (isAr) "مستندات" else "Docs"
        TextKey.LINKS_TAB -> if (isAr) "روابط" else "Links"
        TextKey.TAP_TO_OPEN_IMAGE -> if (isAr) "اضغط لفتح الصورة" else "Tap to open image"
        TextKey.OPEN_ACTION -> if (isAr) "فتح" else "Open"
        TextKey.FAILED_TO_LOAD_IMAGE -> if (isAr) "تعذر تحميل الصورة" else "Failed to load image"
        TextKey.AUDIO_MESSAGE -> if (isAr) "رسالة صوتية" else "Audio message"
        TextKey.MEDIA_MESSAGE -> if (isAr) "رسالة وسائط" else "Media message"
        TextKey.LOCATION -> if (isAr) "موقع" else "Location"
        TextKey.INTERNAL_NOTE_BADGE -> if (isAr) "ملاحظة داخلية" else "INTERNAL NOTE"
        TextKey.YOU_LABEL -> if (isAr) "أنت" else "You"
        TextKey.ASSIGN_AGENT -> if (isAr) "تعيين وكيل" else "Assign agent"
        TextKey.UNASSIGN_AGENT -> if (isAr) "إلغاء تعيين الوكيل" else "Unassign agent"
        TextKey.MUTE_CONVERSATION -> if (isAr) "كتم المحادثة" else "Mute conversation"
        TextKey.UNMUTE_CONVERSATION -> if (isAr) "إلغاء كتم المحادثة" else "Unmute conversation"
        TextKey.MARK_AS_READ -> if (isAr) "تحديد كمقروء" else "Mark as read"
        TextKey.MARK_AS_UNREAD -> if (isAr) "تحديد كغير مقروء" else "Mark as unread"
        TextKey.ATTACH_DETACH_TAG -> if (isAr) "إرفاق / إزالة وسم" else "Attach / detach tag"
        TextKey.SEND_TEMPLATE -> if (isAr) "إرسال قالب" else "Send template"
        TextKey.SEND_FLOW -> if (isAr) "إرسال تدفق" else "Send flow"
        TextKey.SEND_QUICK_REPLY -> if (isAr) "إرسال رد سريع" else "Send quick reply"
        TextKey.SYNC_CUSTOM_FIELD -> if (isAr) "مزامنة حقل مخصص" else "Sync custom field"
        TextKey.UPDATE_CONTACT -> if (isAr) "تحديث جهة الاتصال" else "Update contact"
        TextKey.DELETE_CHAT -> if (isAr) "حذف المحادثة" else "Delete chat"
        TextKey.ASSIGN_AGENT_TITLE -> if (isAr) "تعيين وكيل" else "Assign agent"
        TextKey.AGENT_ID -> if (isAr) "معرّف الوكيل" else "Agent ID"
        TextKey.ATTACH_DETACH_TAG_TITLE -> if (isAr) "إرفاق / إزالة وسم" else "Attach / detach tag"
        TextKey.TAG_ID -> if (isAr) "معرّف الوسم" else "Tag ID"
        TextKey.ATTACH -> if (isAr) "إرفاق" else "Attach"
        TextKey.DETACH -> if (isAr) "إزالة" else "Detach"
        TextKey.SEND_TEMPLATE_TITLE -> if (isAr) "إرسال قالب" else "Send template"
        TextKey.TEMPLATE_ID -> if (isAr) "معرّف القالب" else "Template ID"
        TextKey.SEND_FLOW_TITLE -> if (isAr) "إرسال تدفق" else "Send flow"
        TextKey.FLOW_ID -> if (isAr) "معرّف التدفق" else "Flow ID"
        TextKey.SEND_QUICK_REPLY_TITLE -> if (isAr) "إرسال رد سريع" else "Send quick reply"
        TextKey.SYNC_CUSTOM_FIELD_TITLE -> if (isAr) "مزامنة حقل مخصص" else "Sync custom field"
        TextKey.FIELD_ID -> if (isAr) "معرّف الحقل" else "Field ID"
        TextKey.FIELD_VALUE -> if (isAr) "قيمة الحقل" else "Field Value"
        TextKey.SYNC -> if (isAr) "مزامنة" else "Sync"
        TextKey.DELETE_CHAT_QUESTION -> if (isAr) "حذف المحادثة؟" else "Delete chat?"
        TextKey.DELETE_CHAT_ENDPOINT_HINT -> if (isAr) "سيستدعي هذا إجراء حذف المحادثة لجهة الاتصال الحالية." else "This calls the delete chat endpoint for this contact."
        TextKey.CALL_UNAVAILABLE -> if (isAr) "الاتصال غير متاح" else "Call unavailable"
        TextKey.CALL_UNAVAILABLE_MESSAGE -> if (isAr) "رقم الهاتف غير متاح لجهة الاتصال هذه." else "Phone number is unavailable for this contact."
        TextKey.OK -> if (isAr) "حسنًا" else "OK"
        TextKey.LAST_UPDATED -> if (isAr) "آخر تحديث" else "LAST UPDATED"
        TextKey.BACKEND_TOOLS -> if (isAr) "أدوات الخادم" else "Backend tools"
        TextKey.PROFILE -> if (isAr) "الملف الشخصي" else "Profile"
        TextKey.SYNC_SUPPORT_DATA -> if (isAr) "مزامنة بيانات الدعم" else "Sync support data"
        TextKey.CREATE_UPDATE_TAG -> if (isAr) "إنشاء / تحديث وسم" else "Create / Update Tag"
        TextKey.TAG_NAME -> if (isAr) "اسم الوسم" else "Tag name"
        TextKey.TAG_COLOR_HEX -> if (isAr) "لون الوسم #hex" else "Tag color #hex"
        TextKey.TAG_ID_OPTIONAL -> if (isAr) "معرّف الوسم (اختياري)" else "Tag ID (optional)"
        TextKey.SAVE -> if (isAr) "حفظ" else "Save"
        TextKey.CREATE_UPDATE_REPLY -> if (isAr) "إنشاء / تحديث رد" else "Create / Update Reply"
        TextKey.REPLY_NAME -> if (isAr) "اسم الرد" else "Reply name"
        TextKey.REPLY_TEXT -> if (isAr) "نص الرد" else "Reply text"
        TextKey.REPLY_ID_OPTIONAL -> if (isAr) "معرّف الرد (اختياري)" else "Reply ID (optional)"
        TextKey.ADD_CONTACT_TITLE -> if (isAr) "إضافة جهة اتصال" else "Add Contact"
        TextKey.EMAIL_OPTIONAL -> if (isAr) "البريد الإلكتروني (اختياري)" else "Email (optional)"
        TextKey.ADD -> if (isAr) "إضافة" else "Add"
        TextKey.CANNOT_SHARE_UNAVAILABLE -> if (isAr) "لا يمكن مشاركة عنصر غير متاح" else "Cannot share unavailable item"
        TextKey.CANNOT_DOWNLOAD_UNAVAILABLE -> if (isAr) "لا يمكن تنزيل عنصر غير متاح" else "Cannot download unavailable item"
        TextKey.DOWNLOADING -> if (isAr) "جارٍ التنزيل..." else "Downloading..."
        TextKey.UNABLE_TO_START_DOWNLOAD -> if (isAr) "تعذر بدء التنزيل" else "Unable to start download"
        TextKey.SEARCH_CONTACTS -> if (isAr) "البحث في جهات الاتصال" else "Search contacts"
        TextKey.LOADING_CONTACTS -> if (isAr) "جارٍ تحميل جهات الاتصال..." else "Loading contacts..."
        TextKey.NOTE_BY -> if (isAr) "ملاحظة بواسطة" else "Note by"
        TextKey.LOADING_IMAGE -> if (isAr) "جارٍ تحميل الصورة..." else "Loading image..."
        TextKey.POWERED_BY_WIDERS -> if (isAr) "بدعم من وايدرز" else "Powered by Widers"
        TextKey.META_APPROVED_PARTNER -> if (isAr) "شريك معتمد من ميتا" else "Meta Approved Partner"
    }
}
