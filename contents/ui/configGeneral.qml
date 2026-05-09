import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
  id: root

  property alias cfg_monkeytypeUsername: usernameField.text
  property alias cfg_monkeytypeApeKey: apeKeyField.text
  property alias cfg_daysToShow: daysToShowSpin.value
  property alias cfg_refreshInterval: refreshIntervalCombo.value
  property alias cfg_showCurrentWeekOnly: showCurrentWeekOnlyCheck.checked
  property alias cfg_weekStartDay: weekStartDayCombo.value
  property alias cfg_highlightCurrentDay: highlightCurrentDayCheck.checked
  property alias cfg_themeName: themeCombo.value
  property alias cfg_colorMode: colorModeCombo.value
  property alias cfg_sizeMode: sizeModeCombo.value
  property alias cfg_fixedWidth: fixedWidthSpin.value

  ColumnLayout {
    anchors.fill: parent
    spacing: Kirigami.Units.largeSpacing

    Kirigami.FormLayout {
      Layout.fillWidth: true

      QQC2.TextField {
        id: usernameField
        placeholderText: i18n("Monkeytype username")
        Kirigami.FormData.label: i18n("Username")
      }

      QQC2.TextField {
        id: apeKeyField
        placeholderText: i18n("ApeKey")
        echoMode: TextInput.Password
        Kirigami.FormData.label: i18n("ApeKey")
      }

      QQC2.SpinBox {
        id: daysToShowSpin
        from: 1
        to: 7
        value: 7
        Kirigami.FormData.label: i18n("Days to show")
      }

      QQC2.ComboBox {
        id: refreshIntervalCombo
        property int value: 21600
        textRole: "text"
        valueRole: "value"
        model: [
          {
            value: 900,
            text: i18n("15 minutes")
          },
          {
            value: 1800,
            text: i18n("30 minutes")
          },
          {
            value: 3600,
            text: i18n("1 hour")
          },
          {
            value: 7200,
            text: i18n("2 hours")
          },
          {
            value: 14400,
            text: i18n("4 hours")
          },
          {
            value: 21600,
            text: i18n("6 hours")
          },
          {
            value: 43200,
            text: i18n("12 hours")
          },
          {
            value: 86400,
            text: i18n("24 hours")
          }
        ]
        currentIndex: Math.max(0, model.findIndex(item => item.value === value))
        onActivated: value = currentValue
        Kirigami.FormData.label: i18n("Refresh interval")
      }

      QQC2.ComboBox {
        id: weekStartDayCombo
        property string value: "monday"
        textRole: "text"
        valueRole: "value"
        model: [
          {
            value: "sunday",
            text: i18n("Sunday")
          },
          {
            value: "monday",
            text: i18n("Monday")
          },
          {
            value: "tuesday",
            text: i18n("Tuesday")
          },
          {
            value: "wednesday",
            text: i18n("Wednesday")
          },
          {
            value: "thursday",
            text: i18n("Thursday")
          },
          {
            value: "friday",
            text: i18n("Friday")
          },
          {
            value: "saturday",
            text: i18n("Saturday")
          }
        ]
        currentIndex: Math.max(0, model.findIndex(item => item.value === value))
        onActivated: value = currentValue
        Kirigami.FormData.label: i18n("Week start day")
      }

      QQC2.ComboBox {
        id: themeCombo
        property string value: "standard"
        textRole: "text"
        valueRole: "value"
        model: [
          {
            value: "standard",
            text: i18n("Monkeytype")
          },
          {
            value: "githubDark",
            text: i18n("GitHub Green")
          },
          {
            value: "halloween",
            text: i18n("Halloween")
          },
          {
            value: "teal",
            text: i18n("Teal")
          },
          {
            value: "leftPad",
            text: i18n("@left_pad")
          },
          {
            value: "dracula",
            text: i18n("Dracula")
          },
          {
            value: "blue",
            text: i18n("Blue")
          },
          {
            value: "panda",
            text: i18n("Panda")
          },
          {
            value: "sunny",
            text: i18n("Sunny")
          },
          {
            value: "pink",
            text: i18n("Pink")
          },
          {
            value: "solarizedDark",
            text: i18n("Solarized Dark")
          },
          {
            value: "solarizedLight",
            text: i18n("Solarized Light")
          }
        ]
        currentIndex: Math.max(0, model.findIndex(item => item.value === value))
        onActivated: value = currentValue
        Kirigami.FormData.label: i18n("Theme")
      }

      QQC2.ComboBox {
        id: colorModeCombo
        property string value: "opacity"
        textRole: "text"
        valueRole: "value"
        model: [
          {
            value: "opacity",
            text: i18n("Opacity")
          },
          {
            value: "grade",
            text: i18n("Grade")
          }
        ]
        currentIndex: Math.max(0, model.findIndex(item => item.value === value))
        onActivated: value = currentValue
        Kirigami.FormData.label: i18n("Color mode")
      }

      QQC2.ComboBox {
        id: sizeModeCombo
        property string value: "flexible"
        textRole: "text"
        valueRole: "value"
        model: [
          {
            value: "flexible",
            text: i18n("Flexible")
          },
          {
            value: "fixed",
            text: i18n("Fixed")
          }
        ]
        currentIndex: Math.max(0, model.findIndex(item => item.value === value))
        onActivated: value = currentValue
        Kirigami.FormData.label: i18n("Size mode")
      }

      QQC2.SpinBox {
        id: fixedWidthSpin
        from: 60
        to: 2000
        value: 129
        visible: sizeModeCombo.value === "fixed"
        Kirigami.FormData.label: i18n("Fixed width (px)")
      }

      QQC2.CheckBox {
        id: showCurrentWeekOnlyCheck
        text: i18n("Show current week only")
      }

      QQC2.CheckBox {
        id: highlightCurrentDayCheck
        text: i18n("Highlight current day")
      }
    }
  }
}
