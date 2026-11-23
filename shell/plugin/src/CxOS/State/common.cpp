#include "common.hpp"

#include <qstandardpaths.h>

namespace cxos::shell::state {

using Qt::StringLiterals::operator""_s;

Q_LOGGING_CATEGORY(lcState, "cxos.state", QtInfoMsg)

QString stateDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericStateLocation) + u"/cxos"_s;
}

QString monitorStateDir() {
    return stateDir() + u"/monitors"_s;
}

QString runtimeDir() {
    return QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation) + u"/cxos"_s;
}

QString monitorRuntimeDir() {
    return runtimeDir() + u"/monitors"_s;
}

} // namespace cxos::shell::state
