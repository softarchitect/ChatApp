package com.widers.widerchat.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.widers.widerchat.domain.model.AppLocale
import com.widers.widerchat.domain.model.ConversationSatisfaction

enum class SatisfactionBadgeVariant {
    COMPACT,
    REGULAR
}

@Composable
fun SatisfactionBadge(
    satisfaction: ConversationSatisfaction,
    locale: AppLocale,
    variant: SatisfactionBadgeVariant = SatisfactionBadgeVariant.COMPACT
) {
    val (label, color) = satisfactionBadgeMeta(satisfaction, locale)
    val horizontal = if (variant == SatisfactionBadgeVariant.COMPACT) 6.dp else 8.dp
    val vertical = if (variant == SatisfactionBadgeVariant.COMPACT) 2.dp else 3.dp
    Surface(
        shape = RoundedCornerShape(999.dp),
        color = color.copy(alpha = 0.12f)
    ) {
        Text(
            text = label,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            style = MaterialTheme.typography.labelSmall,
            color = color,
            modifier = Modifier
                .background(Color.Transparent)
                .padding(horizontal = horizontal, vertical = vertical)
        )
    }
}

fun satisfactionBadgeMeta(
    satisfaction: ConversationSatisfaction,
    locale: AppLocale
): Pair<String, Color> = when (satisfaction) {
    ConversationSatisfaction.SATISFIED -> (if (locale == AppLocale.AR) "😊 راضٍ" else "😊 Satisfied") to Color(0xFF059669)
    ConversationSatisfaction.NEUTRAL -> (if (locale == AppLocale.AR) "😐 محايد" else "😐 Neutral") to Color(0xFFD97706)
    ConversationSatisfaction.UNSATISFIED -> (if (locale == AppLocale.AR) "😠 غير راضٍ" else "😠 Unsatisfied") to Color(0xFFDC2626)
    ConversationSatisfaction.NO_RATING -> (if (locale == AppLocale.AR) "⚪ بدون تقييم" else "⚪ No rating") to Color(0xFF64748B)
}
