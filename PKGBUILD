# Maintainer: Gordian Edenhofer <gordian.edenhofer[at]yahoo[dot]de>

pkgname=unity-editor-bin
pkgver=5.1.0f3+2015082501
pkgrel=1
pkgdesc="The world's most popular development platform for creating 2D and 3D multiplatform games and interactive experiences"
arch=('x86_64')
license=('custom')
url="https://unity3d.com/"
depends=('desktop-file-utils' 'xdg-utils' 'gcc-multilib' 'libgl' 'glu' 'nss' 'libpng12' 'libxtst' 'monodevelop')
optdepends=('ffmpeg: for WebGL exporting'
            'nodejs: for WebGL exporting'
            'java-runtime: for WebGL exporting'
            'gzip: for WebGL exporting'
            'java-environment: for Android and Tizen exporting'
            'android-sdk: for Android Remote'
            'android-udev: for Android Remote')
provides=('unity-editor')
conflicts=('unity-editor')
options=(!strip)
install=${pkgname}.install
source=("https://unity3d.com/legal/eula"
        "http://download.unity3d.com/download_unity/unity-editor-${pkgver}_amd64.deb")
md5sums=('0a8c7805f91c1cd46de5bdfba683eeb4'
         'c1c559bb684d00369ee6710be01c3700')

# Prevent compression of the final package since it would take too long (sereausly!)
PKGEXT='.pkg.tar'

package() {
    bsdtar xf data.tar.gz

    # Moving stuff in place
    mv usr "${pkgdir}"
    mv opt "${pkgdir}"

    # Setting permissions on chrome-sandbox - necessary to run the program
    chown root:root "${pkgdir}"/opt/Unity/Editor/chrome-sandbox
    chmod 4755 "${pkgdir}"/opt/Unity/Editor/chrome-sandbox

    # Linking binaries
    mkdir -p "${pkgdir}"/usr/bin
    echo -e "#!/bin/sh\nexec /opt/Unity/Editor/Unity \"$@\"" > "${pkgdir}"/usr/bin/unity-editor
    echo -e "#!/bin/sh\nexec /opt/Unity/MonoDevelop/bin/monodevelop \"$@\"" > "${pkgdir}"/usr/bin/unity-monodevelop
    chmod 755 "${pkgdir}"/usr/bin/unity-editor "${pkgdir}"/usr/bin/unity-monodevelop

    # Moving the license in place
    install -Dm644 "${srcdir}/eula" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
