set(DEPOT_TOOLS_INSTALL_DIR ${CMAKE_EXTERNAL_BINARY_DIR}/depot_tools)
set(DEPOT_TOOLS_BIN_DIR ${DEPOT_TOOLS_INSTALL_DIR}/src/depot_tools)
set(CEF_SVN http://chromiumembedded.googlecode.com/svn/trunk/@282)

ProcessorCount(CPU_COUNT)

ExternalProject_Add(
    depot_tools
    SVN_REPOSITORY http://src.chromium.org/svn/trunk/tools/depot_tools
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    PREFIX ${DEPOT_TOOLS_INSTALL_DIR}
)

if(PYTHON_VERSION_MAJOR EQUAL 3)
  ExternalProject_Add_Step(
    depot_tools
    fix_python_scripts
    COMMAND ${CMAKE_SCRIPT_PATH}/fix_python_depot_tools.sh
    DEPENDEES build
    WORKING_DIRECTORY ${DEPOT_TOOLS_BIN_DIR}
  )
endif()

ExternalProject_Add(
    chromium
    URL https://commondatastorage.googleapis.com/chromium-browser-official/chromium-14.0.809.0.tar.bz2
    URL_MD5 7c5850e9fc9c2f3e42e7b0d63a295a09
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    BUILD_IN_SOURCE 1
    INSTALL_COMMAND ${CMAKE_SCRIPT_PATH}/fix_chromium_path.sh
)

ExternalProject_Add(
	fetch_cef
    SVN_REPOSITORY ${CEF_SVN}
    UPDATE_COMMAND ""
    PATCH_COMMAND ${CMAKE_SCRIPT_PATH}/patch.sh ${CMAKE_SOURCE_DIR}/cmake/patches/cef.patch
    CONFIGURE_COMMAND ""
    BUILD_COMMAND "" 
    INSTALL_COMMAND ""
)


ExternalProject_Add(
    cef
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND "" 
    BUILD_IN_SOURCE 1
    INSTALL_COMMAND ""
)

ExternalProject_Get_Property(
    chromium
    source_dir
)
set(CHROMIUM_SOURCE_DIR ${source_dir})
ExternalProject_Get_Property(
    fetch_cef
    source_dir
)
set(CEF_SOURCE_DIR ${source_dir})

ExternalProject_Add_Step(
    cef
    copy_files
    COMMAND cp -r ${CEF_SOURCE_DIR} ./cef
    DEPENDERS download
    WORKING_DIRECTORY ${CHROMIUM_SOURCE_DIR}/src
)

ExternalProject_Add_Step(
    cef
    glib-2-32-patch
    COMMAND ${CMAKE_SCRIPT_PATH}/patch.sh ${CMAKE_SOURCE_DIR}/cmake/patches/cef_glib_2_32_compile.patch
    DEPENDERS patch
    WORKING_DIRECTORY ${CHROMIUM_SOURCE_DIR}/src
)

ExternalProject_Add_Step(
    cef
    gcc-4-7-patch
    COMMAND ${CMAKE_SCRIPT_PATH}/patch.sh ${CMAKE_SOURCE_DIR}/cmake/patches/cef_gcc47_compile_fix.patch
    DEPENDERS patch
    WORKING_DIRECTORY ${CHROMIUM_SOURCE_DIR}/src
)


ExternalProject_Add_Step(
    cef
    config_cef
    COMMAND ${CMAKE_SCRIPT_PATH}/depot_tools_wrapper.sh ${DEPOT_TOOLS_BIN_DIR} ./cef_create_projects.sh
    DEPENDEES download
    DEPENDERS configure
    WORKING_DIRECTORY ${CHROMIUM_SOURCE_DIR}/src/cef
)

ExternalProject_Add_Step(
    cef
    build_cef
    COMMAND ${CMAKE_SCRIPT_PATH}/depot_tools_wrapper.sh ${DEPOT_TOOLS_BIN_DIR} make cef_desura -j${CPU_COUNT} BUILDTYPE=Release
    DEPENDEES configure
    DEPENDERS build
    WORKING_DIRECTORY ${CHROMIUM_SOURCE_DIR}/src
)

add_dependencies(cef depot_tools)
add_dependencies(cef chromium)
add_dependencies(cef fetch_cef)

set(CEF_LIB_DIR ${CHROMIUM_SOURCE_DIR}/src/out/Release/lib.target)
set(CEF_LIBRARIES "${CEF_LIB_DIR}/libcef_desura.so")
set(CEF_INCLUDE_DIRS "${CEF_SOURCE_DIR}")

install(FILES ${CEF_LIBRARIES}
        DESTINATION ${LIB_INSTALL_DIR})
