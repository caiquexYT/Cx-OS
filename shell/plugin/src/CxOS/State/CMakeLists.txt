qml_module(cxos-state
    URI CxOS.State
    INCLUDE_PREFIX state
    SOURCES
        common.cpp
        rootnodes.cpp
    DEPENDENCIES
        CxOS.Settings
)
target_link_libraries(cxos-state PUBLIC cxos-settings)
