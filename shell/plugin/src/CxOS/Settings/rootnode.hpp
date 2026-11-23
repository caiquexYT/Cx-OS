#pragma once

#include "common.hpp"
#include "objectnode.hpp"
#include "settingsfile.hpp"

namespace cxos::shell::settings {

class RootNode : public ObjectNode {
    Q_OBJECT

    Q_PROPERTY(QList<cxos::shell::settings::Diagnostic> diagnostics READ diagnostics NOTIFY diagnosticsChanged)

public:
    explicit RootNode(bool watch, const QString& path, RootNode* fallback, QObject* parent = nullptr);

    [[nodiscard]] QList<Diagnostic> diagnostics() const;

    void load();

signals:
    void diagnosticsChanged();
    void treeLoaded(cxos::shell::settings::RootNode* self);
    void treeLoadFailed(cxos::shell::settings::RootNode* self, const QString& error);
    void treeSaveFailed(cxos::shell::settings::RootNode* self, const QString& error);

private:
    SettingsFile* const m_file;
    QList<Diagnostic> m_diagnostics;

    void reloadFromFile();
    void saveToFile();
};

} // namespace cxos::shell::settings
