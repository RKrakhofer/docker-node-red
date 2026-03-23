# Umsatzsteuer bei Strombezug und Einspeisung

## Akteure

| Akteur | Rolle |
|--------|-------|
| **Spotty** (aWATTar/Spotty Energy) | Stromlieferant und -abnehmer, dynamischer Tarif |
| **Ich** (PV-Anlagenbetreiber) | Verbraucher und Einspeiser |
| **Finanzamt** | Empfänger der Umsatzsteuer |

## EPEX Spot-Preis

Der EPEX-Börsenpreis wird **netto** gehandelt — ohne jede Umsatzsteuer.
Die aWATTar/Spotty API liefert diesen Preis in **ct/kWh netto**.

---

## Strombezug (Spotty → Ich)

![Geldflüsse beim Strombezug](ust-bezug.png)

Spotty liefert mir Strom. Als Leistungserbringer stellt Spotty **auf alles** 20 % USt in Rechnung.

### Formel

```
Bezugspreis = (EPEX_netto + Aufschlag_netto) × 1,20
```

Äquivalent geschrieben:

```
Bezugspreis = (EPEX_netto × 1,20) + (Aufschlag_netto × 1,20)
            = EPEX_brutto + Aufschlag_brutto
```

### Erklärung

| Komponente | Netto | USt (20 %) | Brutto |
|-----------|-------|-----------|--------|
| EPEX-Preis | variabel (Börse) | Ja, ich zahle | EPEX × 1,20 |
| Spotty-Aufschlag | fix (Vertrag) | Ja, ich zahle | Aufschlag × 1,20 |

**Warum USt auf alles?** Spotty erbringt mir eine Leistung (Stromlieferung). Auf jede Leistung eines Unternehmers an einen Endverbraucher fällt USt an. Sowohl der Energiepreis (EPEX) als auch die Dienstleistung (Aufschlag) sind Teil dieser Leistung.

---

## Einspeisung (Ich → Spotty)

![Geldflüsse bei Einspeisung](ust-einspeisung.png)

Ich liefere Strom an Spotty. Hier drehen sich die Rollen:

- **Ich** bin der Lieferant (PV-Strom)
- **Spotty** ist der Abnehmer und verrechnet seinen Aufschlag als Gebühr

### Formel

```
Einspeiseerlös = EPEX_netto − (Aufschlag_netto × 1,20)
               = EPEX_netto − Aufschlag_brutto
```

### Erklärung

| Komponente | Betrag | USt? | Begründung |
|-----------|--------|------|------------|
| EPEX-Vergütung | EPEX_netto | **Nein** | Ich bekomme den Börsenpreis netto gutgeschrieben |
| Spotty-Aufschlag (Abzug) | Aufschlag_brutto | **Ja** | Spotty verrechnet **mir** seine Dienstleistungsgebühr — auf die stellt Spotty USt in Rechnung |

### Warum EPEX netto?

Der EPEX-Preis ist der Marktpreis, den Spotty am Spotmarkt für meinen Strom erlöst. Dieser wird mir 1:1 netto gutgeschrieben — Spotty verdient daran nichts, das ist ein Durchlaufposten.

### Warum Aufschlag brutto?

Der Aufschlag ist **Spottys Dienstleistung an mich** (Vermarktung, Bilanzierung, Abrechnung). Auf diese Dienstleistung muss Spotty USt verrechnen — und ich zahle sie. Deshalb wird der Aufschlag **brutto** von meinem Erlös abgezogen.

### Was ist mit USt auf meinen Strom?

PV-Anlagen ≤ 35 kWp sind in Österreich seit 1.1.2024 mit **Nullsteuersatz** belegt (§ 28 Abs. 62 UStG). Ich stelle 0 % USt auf meinen eingespeisten Strom in Rechnung. Das heißt: Ich bekomme den EPEX-Preis netto, ohne dass ich darauf USt abführen muss.

---

## Zahlenbeispiel

Annahmen:
- EPEX Spot-Preis: **5,00 ct/kWh netto**
- Spotty-Aufschlag: **1,49 ct/kWh netto** (= 1,79 ct/kWh brutto)

### Bezug (ich kaufe 1 kWh)

```
Bezugspreis = (5,00 + 1,49) × 1,20 = 6,49 × 1,20 = 7,79 ct/kWh brutto
```

| | Netto | + USt | = Brutto |
|--|-------|-------|----------|
| EPEX | 5,00 | 1,00 | 6,00 |
| Aufschlag | 1,49 | 0,30 | 1,79 |
| **Gesamt** | **6,49** | **1,30** | **7,79** |

### Einspeisung (ich verkaufe 1 kWh)

```
Einspeiseerlös = 5,00 − 1,79 = 3,21 ct/kWh
```

| | Betrag | USt-relevant? |
|--|--------|--------------|
| EPEX-Gutschrift | +5,00 (netto) | Nein (Durchlaufposten) |
| Aufschlag-Abzug | −1,79 (brutto) | Ja (Spottys Gebühr an mich) |
| **Netto-Erlös** | **+3,21** | |

---

## Schwellenwert: Ab wann lohnt sich Einspeisung nicht?

Einspeisung lohnt sich nicht mehr, wenn der Erlös ≤ 0 wird:

```
EPEX_netto − Aufschlag_brutto ≤ 0
EPEX_netto ≤ 1,79 ct/kWh
```

Bei einem EPEX-Preis **unter 1,79 ct/kWh netto** kostet die Einspeisung mehr als sie bringt → Einspeisung abschalten.

---

## Zusammenfassung

```
BEZUG:       Ich zahle USt auf ALLES (EPEX + Aufschlag)
EINSPEISUNG: Ich bekomme EPEX netto, zahle aber Aufschlag brutto
```

| Vorgang | Wer leistet? | USt auf EPEX | USt auf Aufschlag | USt ans Finanzamt |
|---------|-------------|-------------|------------------|-------------------|
| Bezug | Spotty → Ich | Ja (ich zahle) | Ja (ich zahle) | Spotty führt ab |
| Einspeisung | Ich → Spotty | Nein (netto) | Ja (Spotty verrechnet mir) | Spotty führt ab |

> **Finanzamt** erhält die USt immer von **Spotty** — ich zahle sie indirekt über den Preis.
> Auf meinen eingespeisten PV-Strom fällt **0 % USt** an (Nullsteuersatz PV ≤ 35 kWp).
