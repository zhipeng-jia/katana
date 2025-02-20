# Link-time reconfiguration via tsuba::Preload and tsuba::RegisterFileStorage
# is easiest to maintain if tsuba and its related libraries are always shared.
#
# Runtime customization of tsuba can be achieved in the standard ways, e.g.,
# - LD_PRELOAD=<my-lib>
#   where my-lib implements tsuba::Preload/tsuba::PreloadFini
# - Symbolically link libtsuba-preload.so to my-lib
# - Adjust LD_LIBRARY_PATH to include a directory, which has
#   libtsuba-preload.so that points to my-lib
add_library(tsuba-preload SHARED)
add_library(tsuba SHARED)

add_dependencies(lib tsuba tsuba-preload)

set(sources
  src/AddProperties.cpp
  src/AsyncOpGroup.cpp
  src/Errors.cpp
  src/FaultTest.cpp
  src/file.cpp
  src/FileFrame.cpp
  src/FileStorage.cpp
  src/FileView.cpp
  src/GlobalState.cpp
  src/LocalStorage.cpp
  src/MemoryNameServerClient.cpp
  src/NameServerClient.cpp
  src/ParquetReader.cpp
  src/ParquetWriter.cpp
  src/RDG.cpp
  src/RDGCore.cpp
  src/RDGHandleImpl.cpp
  src/RDGLineage.cpp
  src/RDGMeta.cpp
  src/RDGPartHeader.cpp
  src/RDGPrefix.cpp
  src/RDGSlice.cpp
  src/ReadGroup.cpp
  src/tsuba.cpp
  src/WriteGroup.cpp
)

target_sources(tsuba PRIVATE ${sources})
target_sources(tsuba-preload PRIVATE src/Preload.cpp)

foreach(target tsuba tsuba-preload)
  target_include_directories(${target} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
  )
  set_common_katana_library_options(${target} ALWAYS_SHARED)
endforeach()

target_link_libraries(tsuba-preload PUBLIC katana_support)
target_link_libraries(tsuba PUBLIC tsuba-preload katana_support)

install(
  DIRECTORY include/
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
  COMPONENT dev
  FILES_MATCHING PATTERN "*.h"
)

install(TARGETS tsuba tsuba-preload
  EXPORT KatanaTargets
  LIBRARY
    DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    COMPONENT shlib
  ARCHIVE
    DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    COMPONENT lib
  INCLUDES DESTINATION "${RELATIVE_INCLUDE_FROM_INSTALL_PREFIX}"
)
