/*
 * Static cmtkconfig.h for vendored CMTK build within cmtkr R package.
 * Replaces the CMake-generated config header.
 */

#ifndef __cmtkconfig_h_included__
#define __cmtkconfig_h_included__

#define CMTK_VERSION_MAJOR 3
#define CMTK_VERSION_MINOR 4
#define CMTK_VERSION_PATCH "0"
#define CMTK_VERSION_STRING "3.4.0"

// Unless in "DEBUG" build, turn off AlgLib assertions
#ifndef DEBUG
#define NO_AP_ASSERT 1
#endif

//
// Configuration options
//

/* #undef CMTK_BUILD_DEMO */
/* #undef CMTK_BUILD_NRRD */
/* #undef CMTK_USE_DCMTK */
/* #undef CMTK_USE_LZMA */
/* #undef CMTK_USE_FFTW_FOUND */
/* #undef CMTK_USE_BZIP2 */
/* #undef CMTK_USE_SQLITE */

#define CMTK_USE_SMP 1

#if defined(__APPLE__)
#define CMTK_USE_GCD 1
#elif !defined(_MSC_VER)
#define CMTK_USE_PTHREADS 1
#define HAVE_PTHREAD_H 1
#endif

#define CMTK_COORDINATES_DOUBLE 1
#ifndef CMTK_COORDINATES_DOUBLE
#  define CMTK_COORDINATES_FLOAT 1
#endif

#define CMTK_DATA_DOUBLE 1
#ifndef CMTK_DATA_DOUBLE
#  define CMTK_DATA_FLOAT 1
#endif

#define CMTK_NUMERICS_DOUBLE 1
#ifndef CMTK_NUMERICS_DOUBLE
#  define CMTK_NUMERICS_FLOAT 1
#endif

#define CMTK_COMPILER_VAR_AUTO_ARRAYSIZE 1

// Standard POSIX headers available on macOS and Linux
#define HAVE_DIRENT_H 1
#define HAVE_FCNTL_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_STDINT_H 1
#define HAVE_UNISTD_H 1
#define HAVE_SYS_IOCTL_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TIMES_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_UTSNAME_H 1
#define HAVE_TERMIOS_H 1

/* #undef HAVE_IEEEFP_H */
#if defined(__linux__)
#define HAVE_MALLOC_H 1
#endif
/* #undef HAVE_VALUES_H */

/* #undef HAVE_HASH_MAP */
/* #undef HAVE_HASH_MAP_H */

#define HAVE_UNORDERED_MAP 1
/* #undef HAVE_UNORDERED_MAP_TR1 */

/* #undef WORDS_BIGENDIAN */
/* #undef CMTK_USE_STAT64 */

/// Macro to prevent warnings from unused function arguments.
#define UNUSED(a) ((void)a)

#if defined(_WIN32)
#  define random rand
#  define srandom srand
#  define CMTK_PATH_SEPARATOR '\\'
#  define CMTK_PATH_SEPARATOR_STR "\\"
#  ifdef _MSC_VER
#    define _CRT_SECURE_NO_DEPRECATE
#    pragma warning ( disable: 4068 )
#    pragma warning(disable: 4290)
#    define _POSIX_
#    define NOMINMAX
#    include <Windows.h>
#    if _MSC_VER >= 1900
#      define STDC99
#    else
#      define snprintf _snprintf
#      define strdup _strdup
#    endif
#    include <float.h>
inline int finite( const double x ) { return _finite(x); }
#  endif
#  ifndef PATH_MAX
#    define PATH_MAX 1024
#  endif
#else
#  define CMTK_PATH_SEPARATOR '/'
#  define CMTK_PATH_SEPARATOR_STR "/"
#ifndef HAVE_FINITE
#include <math.h>
inline int finite( const double x ) { return isfinite(x); }
#endif
#endif

#endif // #ifndef __cmtkconfig_h_included__
