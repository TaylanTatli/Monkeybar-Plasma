import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

import "../code/monkeytypeService.js" as MonkeytypeService

PlasmoidItem {
    id: root
    Layout.preferredWidth: sizeMode === "fixed" ? fixedWidth : compactRoot.implicitWidth

    property string username: plasmoid.configuration.monkeytypeUsername || ""
    property string apeKey: plasmoid.configuration.monkeytypeApeKey || ""
    property int refreshInterval: plasmoid.configuration.refreshInterval || 21600
    property bool showCurrentWeekOnly: plasmoid.configuration.showCurrentWeekOnly || false
    property string weekStartDay: plasmoid.configuration.weekStartDay || ""
    property bool highlightCurrentDay: plasmoid.configuration.highlightCurrentDay || false
    property string themeName: plasmoid.configuration.themeName || "standard"
    property string colorMode: plasmoid.configuration.colorMode || "opacity"
    property int daysToShow: plasmoid.configuration.daysToShow || 7
    property string shortcutRefresh: plasmoid.configuration.shortcutRefresh || ""
    property string shortcutOpenMonkeytype: plasmoid.configuration.shortcutOpenMonkeytype || ""
    property string shortcutOpenProfile: plasmoid.configuration.shortcutOpenProfile || ""
    property string sizeMode: plasmoid.configuration.sizeMode || "flexible"
    property int fixedWidth: plasmoid.configuration.fixedWidth || Math.max(daysToShow * (boxSize + boxMargin), 100)

    property var activityData: []
    property bool busy: false
    property string displayMode: "empty"
    property int currentStreak: 0
    property int maxStreak: 0
    property string statusTitle: i18n("MonkeyBar")
    property string statusSubtitle: i18n("Waiting for data")

    readonly property var themeMap: ({
        standard: { text: "#000000", meta: "#666666", grade4: "#e2b714", grade3: "#f0c730", grade2: "#f5d65b", grade1: "#fae588", grade0: "#ebedf0" },
        githubDark: { text: "#ffffff", meta: "#dddddd", grade4: "#27d545", grade3: "#10983d", grade2: "#00602d", grade1: "#003820", grade0: "#161b22" },
        halloween: { text: "#000000", meta: "#666666", grade4: "#03001C", grade3: "#FE9600", grade2: "#FFC501", grade1: "#FFEE4A", grade0: "#ebedf0" },
        teal: { text: "#000000", meta: "#666666", grade4: "#458B74", grade3: "#66CDAA", grade2: "#76EEC6", grade1: "#7FFFD4", grade0: "#ebedf0" },
        leftPad: { text: "#ffffff", meta: "#999999", grade4: "#F6F6F6", grade3: "#DDDDDD", grade2: "#A5A5A5", grade1: "#646464", grade0: "#2F2F2F" },
        dracula: { text: "#f8f8f2", meta: "#666666", grade4: "#ff79c6", grade3: "#bd93f9", grade2: "#6272a4", grade1: "#44475a", grade0: "#282a36" },
        blue: { text: "#C0C0C0", meta: "#666666", grade4: "#4F83BF", grade3: "#416895", grade2: "#344E6C", grade1: "#263342", grade0: "#222222" },
        panda: { text: "#E6E6E6", meta: "#676B79", grade4: "#FF4B82", grade3: "#19f9d8", grade2: "#6FC1FF", grade1: "#34353B", grade0: "#242526" },
        sunny: { text: "#000000", meta: "#666666", grade4: "#a98600", grade3: "#dab600", grade2: "#e9d700", grade1: "#f8ed62", grade0: "#fff9ae" },
        pink: { text: "#000000", meta: "#666666", grade4: "#61185f", grade3: "#a74aa8", grade2: "#ca5bcc", grade1: "#e48bdc", grade0: "#ebedf0" },
        solarizedDark: { text: "#93a1a1", meta: "#586e75", grade4: "#d33682", grade3: "#b58900", grade2: "#2aa198", grade1: "#268bd2", grade0: "#073642" },
        solarizedLight: { text: "#586e75", meta: "#93a1a1", grade4: "#6c71c4", grade3: "#dc322f", grade2: "#cb4b16", grade1: "#b58900", grade0: "#eee8d5" }
    })

    readonly property var weekDayNames: ({
        sunday: 0,
        monday: 1,
        tuesday: 2,
        wednesday: 3,
        thursday: 4,
        friday: 5,
        saturday: 6
    })

    readonly property int boxSize: 14
    readonly property int boxMargin: 4
    readonly property int borderRadius: 3

    preferredRepresentation: compactRepresentation
    activationTogglesExpanded: true
    toolTipMainText: i18n("MonkeyBar")
    toolTipSubText: statusSubtitle

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh Now")
            icon.name: "view-refresh"
            onTriggered: root.refreshData()
        },
        PlasmaCore.Action {
            text: i18n("Open Monkeytype")
            icon.name: "internet-services"
            onTriggered: root.openMonkeytype()
        },
        PlasmaCore.Action {
            text: i18n("Open Profile")
            icon.name: "user-home"
            onTriggered: root.openUserProfile()
        }
    ]

    function theme() {
        return themeMap[themeName] || themeMap.standard;
    }

    function isToday(date) {
        const today = new Date();
        return date.getDate() === today.getDate() && date.getMonth() === today.getMonth() && date.getFullYear() === today.getFullYear();
    }

    function formatDate(date, count) {
        const monthName = date.toLocaleString(Qt.locale(), "MMM");
        const label = count === 1 ? i18n("test") : i18n("tests");

        if (isToday(date)) {
            return i18n("Today: %1 %2", count, label);
        }

        return i18n("%1 %2: %3 %4", monthName, date.getDate(), count, label);
    }

    function gradeForCount(count) {
        if (count === 0) {
            return "grade0";
        }
        if (count < 3) {
            return "grade1";
        }
        if (count < 6) {
            return "grade2";
        }
        if (count < 11) {
            return "grade3";
        }
        return "grade4";
    }

    function baseColorForCount(count) {
        const currentTheme = theme();
        if (colorMode === "grade") {
            return currentTheme[gradeForCount(count)] || currentTheme.grade0;
        }

        return count > 0 ? currentTheme.grade3 : currentTheme.grade0;
    }

    function opacityForCount(count) {
        if (colorMode === "grade") {
            return 1.0;
        }

        if (count === 0) {
            return 1.0;
        }

        return Math.min(0.2 + Math.min(count * 0.08, 0.8), 1.0);
    }

    function generateDates() {
        let weekStart = weekDayNames[weekStartDay];
        if (weekStart === undefined) {
            weekStart = Qt.locale().firstDayOfWeek;
        }
        return MonkeytypeService.getDates(false, showCurrentWeekOnly, weekStart, daysToShow);
    }

    function buildItems(counts) {
        const dates = generateDates();
        const items = [];

        for (let index = 0; index < dates.length; index += 1) {
            items.push({
                date: dates[index],
                count: counts && counts[index] !== undefined ? counts[index] : 0
            });
        }

        return items;
    }

    function openMonkeytype() {
        let url = "https://monkeytype.com";

        Qt.openUrlExternally(url);
    }

    function openUserProfile() {
        if (!username) {
            statusTitle = i18n("MonkeyBar");
            statusSubtitle = i18n("Set your Monkeytype username to open a profile");
            return;
        }

        Qt.openUrlExternally(`https://monkeytype.com/profile/${encodeURIComponent(username)}`);
    }

    function setEmptyState(message) {
        displayMode = "empty";
        currentStreak = 0;
        maxStreak = 0;
        activityData = buildItems();
        statusTitle = i18n("MonkeyBar");
        statusSubtitle = message;
    }

    function refreshData() {
        if (!username) {
            setEmptyState(i18n("Set your Monkeytype username in settings"));
            return;
        }

        busy = true;
        statusTitle = i18n("MonkeyBar");
        statusSubtitle = i18n("Refreshing activity...");

        MonkeytypeService.fetchTypingActivity(username, apeKey, showCurrentWeekOnly, weekDayNames[weekStartDay] || 1, daysToShow)
            .then(result => {
                busy = false;

                currentStreak = result && typeof result.streak === "number" ? result.streak : 0;
                maxStreak = result && typeof result.maxStreak === "number" ? result.maxStreak : 0;

                const activity = Array.isArray(result) ? result : result && result.activity;

                if (Array.isArray(activity) && activity.length === daysToShow) {
                    displayMode = "activity";
                    activityData = buildItems(activity);
                    statusTitle = i18n("MonkeyBar");
                    statusSubtitle = i18n("Updated: Last %1 day(s)", activity.length);
                    return;
                }

                if (currentStreak > 0 || maxStreak > 0) {
                    displayMode = "streak";
                    activityData = buildItems();
                    statusTitle = i18n("Streak: %1 day(s)", currentStreak);
                    statusSubtitle = i18n("Max streak: %1 day(s)", maxStreak);
                    return;
                }

                setEmptyState(i18n("No test data available"));
            })
            .catch(error => {
                busy = false;
                console.error(`MonkeyBar: ${error}`);
                setEmptyState(i18n("Failed to load Monkeytype activity"));
            });
    }

    onUsernameChanged: refreshData()
    onApeKeyChanged: refreshData()
    onShowCurrentWeekOnlyChanged: refreshData()
    onWeekStartDayChanged: refreshData()
    onDaysToShowChanged: refreshData()

    Component.onCompleted: refreshData()

    Timer {
        interval: root.refreshInterval * 1000
        repeat: true
        running: root.refreshInterval > 0 && root.username.length > 0
        onTriggered: root.refreshData()
    }

    compactRepresentation: Item {
        id: compactRoot
        implicitWidth: activityRow.implicitWidth
        implicitHeight: activityRow.implicitHeight
        Layout.preferredWidth: sizeMode === "fixed" ? fixedWidth : implicitWidth

        RowLayout {
            id: activityRow
            anchors.centerIn: parent
            spacing: root.boxMargin

            Repeater {
                model: root.activityData

                delegate: Rectangle {
                    required property var modelData

                    width: root.boxSize
                    height: root.boxSize
                    radius: root.borderRadius
                    color: root.baseColorForCount(modelData.count)
                    opacity: root.opacityForCount(modelData.count)
                    border.width: root.highlightCurrentDay && root.isToday(modelData.date) ? 2 : 1
                    border.color: {
                        if (root.highlightCurrentDay && root.isToday(modelData.date)) {
                            return Kirigami.Theme.highlightColor;
                        }
                        return "transparent";
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: {
                root.expanded = !root.expanded
            }
        }
    }

    fullRepresentation: Item {
        id: fullRoot
        implicitWidth: Kirigami.Units.gridUnit * 14
        implicitHeight: contentColumn.implicitHeight + (Kirigami.Units.smallSpacing * 2)

        ColumnLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: Kirigami.Units.mediumSpacing
            }
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 0
                    PlasmaExtras.Heading {
                        Layout.fillWidth: true
                        level: 4
                        text: root.statusTitle
                    }
                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: root.statusSubtitle
                        font.pixelSize: Kirigami.Units.gridUnit * 0.7
                        opacity: 0.7
                    }
                }
                PlasmaComponents3.BusyIndicator {
                    running: root.busy
                    visible: root.busy
                    Layout.preferredWidth: Kirigami.Units.gridUnit
                    Layout.preferredHeight: Kirigami.Units.gridUnit
                }
            }

            ColumnLayout {
              id: activityList
              Layout.fillWidth: true
              spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.activityData
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Rectangle {
                            width: root.boxSize
                            height: root.boxSize
                            radius: root.borderRadius
                            color: root.baseColorForCount(modelData.count)
                            opacity: root.opacityForCount(modelData.count)
                            border.width: root.highlightCurrentDay && root.isToday(modelData.date) ? 2 : 1
                            border.color: root.highlightCurrentDay && root.isToday(modelData.date) ? "white" : "transparent"
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: root.formatDate(modelData.date, modelData.count)
                            font.pixelSize: Kirigami.Units.gridUnit * 0.8
                        }
                    }
                }
            }
              PlasmaComponents3.Label {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: i18n("Streak: <b>%1</b> (Max: %2)", root.currentStreak, root.maxStreak)
                textFormat: Text.RichText
                font.pixelSize: Kirigami.Units.gridUnit * 0.8
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    icon.name: "view-refresh"
                    ToolTip.visible: hovered
                    ToolTip.text: i18n("Refresh")
                    onClicked: root.refreshData()
                }

                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    icon.name: "internet-services"
                    ToolTip.visible: hovered
                    ToolTip.text: i18n("Open Monkeytype")
                    onClicked: root.openMonkeytype()
                }

                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    icon.name: "user-identity"
                    ToolTip.visible: hovered
                    ToolTip.text: i18n("Profile")
                    onClicked: root.openUserProfile()
                }
            }
        }
    }
}
