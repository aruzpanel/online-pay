package usecase

import (
	"regexp"
	"strconv"
	"strings"

	"go.uber.org/zap"
)

// TopUpResult parse natijasi.
type TopUpResult struct {
	Type         string // "top_up"
	AmountRaw    string // "3.300.000,00"
	AmountInt    int64  // 330000000 (tiyinda: so'm*100 + tiyin)
	Last4        string // "7159" — cartaning oxirgi 4 raqami
	Currency     string // "UZS"
	AmountPretty string
}

// toNumber summani tiyinda qaytaradi (1 so'm = 100 tiyin), kasr (tiyin) qismni
// saqlab. Ikki format keladi: HUMOcardbot "3.300.000,00" (nuqta — minglik,
// vergul — o'nlik) va CardXabarBot "542 400.00" (bo'shliq — minglik, nuqta —
// o'nlik). O'nlik ajratuvchi — oxiridagi, ortidan aynan 2 raqam kelgan belgi;
// qolgan hamma nuqta/vergul/bo'shliq minglik ajratuvchi sifatida tashlanadi.
func toNumber(amount string, log *zap.Logger) (int64, bool) {
	amount = strings.TrimSpace(amount)
	var whole, frac string
	if n := len(amount); n > 3 && (amount[n-3] == ',' || amount[n-3] == '.') {
		whole, frac = amount[:n-3], amount[n-2:]
	} else {
		whole = amount
	}
	whole = strings.NewReplacer(".", "", " ", "", ",", "").Replace(whole)
	normalized := whole
	if frac != "" {
		normalized += "." + frac
	}
	whole, frac, _ = strings.Cut(normalized, ".")
	som, err := strconv.ParseInt(whole, 10, 64)
	if err != nil {
		return 0, false
	}
	// Kasr qismni aniq 2 raqamga keltiramiz (tiyin): "" -> 00, "5" -> 50, "123" -> 12.
	switch {
	case len(frac) == 0:
		frac = "00"
	case len(frac) == 1:
		frac += "0"
	case len(frac) > 2:
		frac = frac[:2]
	}
	tiyin, err := strconv.ParseInt(frac, 10, 64)
	if err != nil {
		return 0, false
	}
	return som*100 + tiyin, true
}

var (
	// Kirim operatsiyasi so'zi (case-insensitive). HUMOcardbot: "To'ldirish"
	// (apostrof turlicha: ' ’ ‘ ` ʻ ´ yoki yo'q). CardXabarBot: "Perevod na
	// kartu" (lotin yoki kirill).
	reTopUpWord = regexp.MustCompile(`(?i)To['’‘` + "`" + `ʻ´]?ldirish|Perevod na kartu|Перевод на карту|Пополнение`)
	// ➕ 3.300.000,00 UZS  ·  ➕ 3 300 000,00 UZS  ·  ➕ 542 400.00 UZS
	reAmount = regexp.MustCompile(`➕\s*(\d[\d.,\s]*[.,]\d{2})\s*([A-Z]{3})`)
	// 💳 HUMOCARD *7159  (oxirgi 4 raqam)
	reCard = regexp.MustCompile(`\*\s*(\d{4})`)
)

// ParseTopUp matndan To'ldirish operatsiyasi bo'lsa ajratib qaytaradi.
func ParseTopUp(text string, log *zap.Logger) *TopUpResult {
	// Unicode no-break space va boshqalarni oddiy bo'shliqqa
	cleaned := strings.ReplaceAll(text, "\u202f", " ")
	cleaned = strings.ReplaceAll(cleaned, "\u00a0", " ")

	if !reTopUpWord.MatchString(cleaned) {
		return nil
	}
	m := reAmount.FindStringSubmatch(cleaned)
	if len(m) != 3 {
		return nil
	}
	amountStr := m[1]
	currency := m[2]

	val, ok := toNumber(amountStr, log)
	if !ok {
		return nil
	}

	var last4 string
	if c := reCard.FindStringSubmatch(cleaned); len(c) == 2 {
		last4 = c[1]
	}

	return &TopUpResult{
		Type:         "top_up",
		AmountRaw:    amountStr,
		AmountInt:    val,
		Last4:        last4,
		Currency:     currency,
		AmountPretty: amountStr + " " + currency,
	}
}
