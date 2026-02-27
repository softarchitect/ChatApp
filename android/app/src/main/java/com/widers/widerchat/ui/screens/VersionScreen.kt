package com.widers.widerchat.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.Image
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.widers.widerchat.R
import com.widers.widerchat.domain.model.AppLocale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VersionScreen(
    modifier: Modifier = Modifier,
    locale: AppLocale,
    onBack: () -> Unit
) {
    val isAr = locale == AppLocale.AR
    val title = if (isAr) "حول وايدرز" else "About Widers"
    val description = if (isAr) {
        "وايدرز منصة معتمدة من ميتا لإدارة محادثات واتساب للأعمال في الوقت الفعلي مع فرق متعددة."
    } else {
        "Widers is a Meta-approved WhatsApp Business Cloud API provider helping teams manage customer conversations at scale."
    }
    val partnerBadge = if (isAr) "شريك معتمد من ميتا" else "META APPROVED PARTNER"
    val versionLabel = if (isAr) "الإصدار" else "Version"
    val buildLabel = if (isAr) "البناء" else "Build"
    val environmentLabel = if (isAr) "البيئة" else "Environment"
    val apiVersionLabel = if (isAr) "إصدار API" else "API Version"
    val whatsappApiLabel = if (isAr) "واجهة WhatsApp Cloud API" else "WhatsApp Cloud API"
    val featuresTitle = if (isAr) "أهم الميزات" else "KEY FEATURES"
    val productionValue = if (isAr) "الإنتاج" else "Production"
    val features = if (isAr) {
        listOf(
            "مراسلة واتساب للأعمال في الوقت الفعلي",
            "إدارة المحادثات بواسطة عدة وكلاء",
            "ملاحظات داخلية وتعاون الفريق",
            "تحليلات وتقارير المحادثات",
            "توجيه الرسائل وتعيينها تلقائيًا",
            "إدارة قوالب الرسائل"
        )
    } else {
        listOf(
            "Real-time WhatsApp Business messaging",
            "Multi-agent conversation management",
            "Internal notes and team collaboration",
            "Conversation analytics and reporting",
            "Automated message routing and assignment",
            "Template message management"
        )
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
        Column(
            modifier = Modifier
                .padding(pad)
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Image(
                        painter = painterResource(id = R.drawable.logo_widers),
                        contentDescription = null,
                        modifier = Modifier
                            .size(120.dp)
                            .padding(top = 4.dp),
                        contentScale = ContentScale.Fit
                    )
                    Text("Widers", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, modifier = Modifier.padding(top = 10.dp))
                    Text(partnerBadge, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
                    Text(
                        description,
                        modifier = Modifier.padding(top = 10.dp),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center
                    )
                }
            }

            Card(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp)) {
                Column(modifier = Modifier.padding(vertical = 4.dp)) {
                    InfoRow(versionLabel, "1.0.0")
                    InfoRow(buildLabel, "2026.02.25")
                    InfoRow(environmentLabel, productionValue)
                    InfoRow(apiVersionLabel, "v2.0")
                    InfoRow(whatsappApiLabel, "v21.0")
                }
            }

            Column(modifier = Modifier.fillMaxWidth()) {
                Text(featuresTitle, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Card(modifier = Modifier.fillMaxWidth().padding(top = 8.dp), shape = RoundedCornerShape(16.dp)) {
                    Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        for (f in features) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Outlined.CheckCircle, null, tint = MaterialTheme.colorScheme.primary)
                                Text(f, modifier = Modifier.padding(start = 10.dp))
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 10.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, fontWeight = FontWeight.Medium)
    }
}
