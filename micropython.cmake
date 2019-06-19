
set(MP ${CMAKE_CURRENT_LIST_DIR}/../micropython)

set(GENHDR ${CMAKE_BINARY_DIR}/genhdr)
include_directories(${MP} 
                    ${GENHDR}/..
                    ${MP}/lib/lwip/src/include
                    ${MP}/extmod/lwip-include
                    )

FILE(GLOB_RECURSE MICROPYTHON_SRC
    "${MP}/py/*.c"
)

set(MICROPYTHON_SRC ${MICROPYTHON_SRC}             
        ${MP}/extmod/moductypes.c
        ${MP}/extmod/modujson.c
        ${MP}/extmod/modure.c
        ${MP}/extmod/moduzlib.c
        ${MP}/extmod/moduheapq.c
        ${MP}/extmod/modutimeq.c
        ${MP}/extmod/moduhashlib.c
        ${MP}/extmod/moducryptolib.c
        ${MP}/extmod/modubinascii.c
        ${MP}/extmod/virtpin.c
        ${MP}/extmod/machine_mem.c
        ${MP}/extmod/machine_pinbase.c
        ${MP}/extmod/machine_signal.c
        ${MP}/extmod/machine_pulse.c
        ${MP}/extmod/machine_i2c.c
        ${MP}/extmod/machine_spi.c
        ${MP}/extmod/modussl_axtls.c
        ${MP}/extmod/modussl_mbedtls.c
        ${MP}/extmod/modurandom.c
        ${MP}/extmod/moduselect.c
        ${MP}/extmod/moduwebsocket.c
        ${MP}/extmod/modwebrepl.c
        ${MP}/extmod/modframebuf.c
        ${MP}/extmod/vfs.c
        ${MP}/extmod/vfs_reader.c
        ${MP}/extmod/vfs_posix.c
        ${MP}/extmod/vfs_posix_file.c
        ${MP}/extmod/vfs_fat.c
        ${MP}/extmod/vfs_fat_diskio.c
        ${MP}/extmod/vfs_fat_file.c
        ${MP}/extmod/utime_mphal.c
        ${MP}/extmod/uos_dupterm.c
        ${MP}/lib/embed/abort_.c
        )

set(micropython_CFLAGS
        -I.
        -I${GENHDR}/..
        -I${CMAKE_SOURCE_DIR}/src
        -I${MP}/
        -I${MP}/py
        -I${CMAKE_CURRENT_LIST_DIR}/libraries/micropython
        -Wall
        -Werror
        -Wpointer-arith
        -Wuninitialized
        -Wno-unused-label
        -std=gnu99
        -Os
        )

#TODO: verify that this works
set_source_files_properties(${MP}/py/gc.c PROPERTIES COMPILE_FLAGS -O3)
set_source_files_properties(${MP}/py/vm.c PROPERTIES COMPILE_FLAGS -O3)

#
SET_SOURCE_FILES_PROPERTIES(${micropython_SOURCE} PROPERTIES COMPILE_FLAGS "-Wall -Werror -Wpointer-arith -Wuninitialized -Wno-unused-label -std=gnu99 -U_FORTIFY_SOURCE -Os")
#add_library(micropython ${micropython_regular_SOURCE} ${GENHDR}/qstrdefs.generated.h)
#target_compile_options(micropython PRIVATE ${micropython_CFLAGS})
#target_compile_definitions(micropython PRIVATE FFCONF_H=\"${MP}/lib/oofatfs/ffconf.h\")
add_custom_command(OUTPUT ${GENHDR}/qstrdefs.generated.h
        COMMAND echo "=======================start========================="
        COMMAND mkdir -p ${GENHDR}
        COMMAND python3 ${MP}/py/makeversionhdr.py ${GENHDR}/mpversion.h
        COMMAND python3 ${MP}/py/makemoduledefs.py --vpath="., .., " ${micropython_SOURCE} ${GENHDR}/moduledefs.h > ${GENHDR}/moduledefs.h
        COMMAND ${CMAKE_C_COMPILER} -E -DNO_QSTR ${micropython_CFLAGS} -DFFCONF_H='\"${MP}/lib/oofatfs/ffconf.h\"' ${MICROPYTHON_SRC} ${CMAKE_CURRENT_LIST_DIR}/libraries/micropython/mpconfigport.h > ${GENHDR}/qstr.i.last
        COMMAND python3 ${MP}/py/makeqstrdefs.py split ${GENHDR}/qstr.i.last ${GENHDR}/qstr ${GENHDR}/qstrdefs.collected.h
        COMMAND python3 ${MP}/py/makeqstrdefs.py cat ${GENHDR}/qstr.i.last ${GENHDR}/qstr ${GENHDR}/qstrdefs.collected.h
        COMMAND cat ${MP}/py/qstrdefs.h ${CMAKE_CURRENT_LIST_DIR}/libraries/micropython/qstrdefsport.h ${GENHDR}/qstrdefs.collected.h | sed [=['s/^Q(.*)/"&"/']=] | ${CMAKE_C_COMPILER} -E ${micropython_CFLAGS} -DFFCONF_H='\"${MP}/lib/oofatfs/ffconf.h\"' - | sed [=['s/^"\(Q(.*)\)"/\1/']=] > ${GENHDR}/qstrdefs.preprocessed.h
        COMMAND python3 ${MP}/py/makeqstrdata.py ${GENHDR}/qstrdefs.preprocessed.h > ${GENHDR}/qstrdefs.generated.h
        COMMAND echo "=======================end========================="
        DEPENDS ${micropython_SOURCE} ${CMAKE_SOURCE_DIR}/../${PROJ}/libraries/micropython/mpconfigport.h
        )