// Stubs for CMTK symbols that are referenced but not needed at runtime.
// cmtkr only reads transforms and applies them to points — no writing,
// no NIFTI support, no volume I/O.

#include <cmtkconfig.h>
#include <IO/cmtkXformIO.h>

void
cmtk::XformIO::WriteNIFTI( const cmtk::Xform*, const std::string& )
{
}
