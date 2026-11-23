qml_module(cxos-models
    URI CxOS.Models
    SOURCES
        filesystemmodel.cpp
        appdb.cpp
    LIBRARIES
        Qt::Gui
        Qt::Multimedia
        Qt::Concurrent
        Qt::Sql
)
