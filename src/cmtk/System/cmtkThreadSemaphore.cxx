/*
// Dispatcher for platform-specific ThreadSemaphore implementation.
// Includes the appropriate .txx based on platform defines.
*/

#include <cmtkconfig.h>
#include <System/cmtkThreadSemaphore.h>

#if defined(CMTK_USE_PTHREADS)
#  if defined(__APPLE__) || defined(__CYGWIN__)
#    include "cmtkThreadSemaphoreAppleIsRetarded.txx"
#  else
#    include "cmtkThreadSemaphorePOSIX.txx"
#  endif
#elif defined(_MSC_VER)
#  include "cmtkThreadSemaphoreWindows.txx"
#else
#  include "cmtkThreadSemaphoreNone.txx"
#endif
