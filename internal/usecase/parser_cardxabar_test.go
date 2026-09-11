package usecase

import (
	"testing"

	"go.uber.org/zap"
)

func TestParseTopUp_Formats(t *testing.T) {
	cases := []struct {
		name  string
		text  string
		want  int64
		last4 string
	}{
		{
			name:  "humo bot",
			text:  "To'ldirish\n➕ 3.300.000,00 UZS\n💳 HUMOCARD *7159",
			want:  330000000,
			last4: "7159",
		},
		{
			name:  "humo bot with tiyin",
			text:  "To'ldirish\n➕ 1.000,01 UZS\n💳 HUMOCARD *7159",
			want:  100001,
			last4: "7159",
		},
		{
			name:  "cardxabar bot",
			text:  "🟢 Perevod na kartu\n➕ 542 400.00 UZS\n💳 ***6203\n📍 UNIBANK QR OPLATY, UZ\n🕐 18.08.26 19:43\n💰 542 500.00 UZS",
			want:  54240000,
			last4: "6203",
		},
		{
			name:  "cardxabar bot with tiyin",
			text:  "🟢 Perevod na kartu\n➕ 140 100.07 UZS\n💳 ***6203\n💰 140 100.07 UZS",
			want:  14010007,
			last4: "6203",
		},
	}
	log := zap.NewNop()
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			r := ParseTopUp(c.text, log)
			if r == nil {
				t.Fatalf("nil natija")
			}
			if r.AmountInt != c.want {
				t.Fatalf("amount: kutilgan %d, olindi %d", c.want, r.AmountInt)
			}
			if r.Last4 != c.last4 {
				t.Fatalf("last4: kutilgan %s, olindi %s", c.last4, r.Last4)
			}
		})
	}
	if ParseTopUp("🔴 Spisanie\n➖ 10 000.00 UZS\n💳 ***6203", log) != nil {
		t.Fatalf("chiqim xabari kirim deb o'qildi")
	}
}
