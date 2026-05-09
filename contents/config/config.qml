import QtQuick
import org.kde.plasma.configuration as PlasmaConfiguration

PlasmaConfiguration.ConfigModel {
  PlasmaConfiguration.ConfigCategory {
    name: i18n("General")
    icon: "configure"
    source: "configGeneral.qml"
  }
}
