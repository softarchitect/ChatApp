package com.widers.widerchat.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material.icons.outlined.CreditCard
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Gavel
import androidx.compose.material.icons.outlined.Policy
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Shield
import androidx.compose.material.icons.outlined.Warning
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.widers.widerchat.core.TextKey
import com.widers.widerchat.core.tr
import com.widers.widerchat.domain.model.AppLocale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TermsScreen(
    modifier: Modifier = Modifier,
    locale: AppLocale,
    onBack: () -> Unit
) {
    val isAr = locale == AppLocale.AR
    val sections = if (isAr) {
        listOf(
            "تسجيل الحساب" to "لاستخدام وايدرز، يجب تسجيل حساب تاجر وتقديم معلومات صحيحة. أنت مسؤول عن الحفاظ على سرية بيانات تسجيل الدخول.",
            "الاستخدام المقبول" to "توافق على استخدام الخدمة لأغراض قانونية فقط وبما يتوافق مع سياسات واتساب للأعمال. يُمنع الإزعاج أو الإساءة أو انتحال الهوية.",
            "الاشتراك والفوترة" to "الوصول إلى وايدرز قائم على الاشتراك. يتم تحصيل الرسوم شهريًا أو سنويًا حسب الباقة المختارة.",
            "اتفاقية مستوى الخدمة" to "نسعى للحفاظ على جاهزية عالية للمنصة. سيتم إشعارك مسبقًا بنوافذ الصيانة المجدولة.",
            "الملكية الفكرية" to "تصميم وميزات منصة وايدرز محمية. وتظل ملكية محتوى ورسائل العملاء الخاصة بك لك.",
            "تحديد المسؤولية" to "إلى أقصى حد يسمح به القانون، لا تتحمل وايدرز المسؤولية عن الأضرار غير المباشرة أو التبعية.",
            "إنهاء الخدمة" to "يجوز لأي طرف إنهاء الخدمة. وتُطبق سياسات الاحتفاظ بالبيانات والحذف وفقًا للاتفاقية.",
            "القانون الحاكم" to "تُحل النزاعات وفق القانون الحاكم المعمول به وبنود تسوية النزاعات."
        )
    } else {
        listOf(
            "Account Registration" to "To use Widers, you must register for a merchant account and provide accurate information. You are responsible for keeping account credentials secure.",
            "Acceptable Use" to "You agree to use the service only for lawful purposes and in compliance with WhatsApp Business policies. No spam, abuse, or impersonation.",
            "Subscription & Billing" to "Access to Widers is subscription-based. Plans are billed monthly or annually according to the selected package.",
            "Service Level Agreement" to "We strive to maintain high platform uptime. Scheduled maintenance windows will be communicated in advance.",
            "Intellectual Property" to "Widers platform design and features are protected. You retain ownership of your own customer content and messages.",
            "Limitation of Liability" to "To the maximum extent permitted by law, Widers is not liable for indirect or consequential damages.",
            "Termination" to "Either party may terminate the service. Data retention and deletion policies apply as defined in the agreement.",
            "Governing Law" to "Any disputes are resolved according to applicable governing law and dispute-resolution terms."
        )
    }

    val icons = listOf(
        Icons.Outlined.AccountCircle,
        Icons.Outlined.Shield,
        Icons.Outlined.CreditCard,
        Icons.Outlined.Schedule,
        Icons.Outlined.Policy,
        Icons.Outlined.Warning,
        Icons.Outlined.ErrorOutline,
        Icons.Outlined.Gavel
    )

    val title = if (isAr) "شروط الخدمة" else "Terms of Service"
    val updatedDate = if (isAr) "25 فبراير 2026" else "February 25, 2026"
    val intro = if (isAr) {
        "تحكم شروط الخدمة هذه وصولك واستخدامك لمنصة وايدرز، بما في ذلك خدمات WhatsApp Business Cloud API وتطبيق الهاتف."
    } else {
        "These Terms of Service govern your access and use of the Widers platform, including our WhatsApp Business Cloud API services and mobile application."
    }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = { Text(title, fontWeight = FontWeight.SemiBold) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, null) } }
            )
        }
    ) { pad ->
        LazyColumn(modifier = Modifier.padding(pad)) {
            item {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(MaterialTheme.colorScheme.secondary.copy(alpha = 0.35f))
                        .padding(horizontal = 20.dp, vertical = 14.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        HorizontalDivider(modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.outline.copy(alpha = 0.4f))
                        Text(
                            "  ${tr(locale, TextKey.LAST_UPDATED)}  ",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        HorizontalDivider(modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.outline.copy(alpha = 0.4f))
                    }
                    Text(
                        updatedDate,
                        modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        intro,
                        modifier = Modifier.padding(top = 12.dp),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            itemsIndexed(sections) { idx, section ->
                Card(
                    modifier = Modifier
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                        .fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Card(
                                shape = RoundedCornerShape(20.dp),
                                colors = CardDefaults.cardColors(containerColor = Color(0xFF0EA5E9).copy(alpha = 0.1f))
                            ) {
                                Icon(icons[idx], null, modifier = Modifier.padding(8.dp), tint = Color(0xFF0EA5E9))
                            }
                            Text(
                                section.first,
                                modifier = Modifier.weight(1f).padding(start = 10.dp),
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                "${idx + 1}".padStart(2, '0'),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        Text(
                            section.second,
                            modifier = Modifier.padding(top = 8.dp),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}
