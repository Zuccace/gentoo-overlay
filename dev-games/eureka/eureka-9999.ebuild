# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit eutils git-r3 git-r3-verify

DESCRIPTION="A map editor for the classic DOOM games, and others such as Heretic and Hexen."
HOMEPAGE="http://eureka-editor.sourceforge.net"
EGIT_REPO_URI="https://git.code.sf.net/p/eureka-editor/git eureka-editor-git"
LICENSE="GPL-2+"
SLOT="0"
IUSE="xinerama +verify-git-sources +create-sums"

case "${PVR}" in
	1.21-r1)
		EGIT_COMMIT="2c43e820d58f0e97efa1e4c2967e06657fa6a32e"
		KEYWORDS="~amd64 -x86"
		pkg_info() {
			einfo "This unoffical version has new 3D view implementation:"
			einfo
			einfo "3D View : rewrote code to sort the active list of draw-walls,"
			einfo "using custom sorting code (implementing QuickSort)."
			einfo ""
			einfo "It previously used std::sort(), but because our wall-distance"
			einfo "comparison function is \"wonky\" (e.g. can be non-reversable or"
			einfo "non-transitive), it was causing the local std::sort() function"
			einfo "to access elements outside of the list (leading to a CRASH)."
		}
		PATCH_VERS="r1-gentoo"
	;;
	9999)
		# placeholder
		true
	;;
	*)
		die "${PN} ebuild doesn't support the requested version of ${PVR}"
	;;
esac

RDEPEND="
	xinerama? ( x11-libs/libXinerama )
	sys-libs/zlib
	media-libs/libpng:0/16
	virtual/jpeg:*
	x11-misc/xdg-utils
	x11-libs/fltk
	x11-libs/libXft"

DEPEND="${RDEPEND}
>=sys-apps/gawk-4.1.0"

src_prepare() {
	default # We'll verify the sources first.
	die on purpose.

	[ -z "$PATCH_VERS" ] && PATCH_VERS="git-p$(git rev-list --count HEAD)-gentoo-$(date --date="$(git show --pretty=%cI HEAD | head -n 1)" +%F) "

	einfo "Patching Makefile on-the-fly..."
	# Modify PREFIX, drop lines using xdg and adjust few compiler flags.
	gawk -i inplace -v "prefix=${D}/usr" -v "libdir=$(get_libdir)" '{if ($1 ~ "^(INSTALL_)?PREFIX=") sub(/=.+$/,"=" prefix); else if ($1 ~ /^xdg-/) next; else if ($1 ~ /^[a-z]+:$/ && seen != "1") {printf "CFLAGS  += -I/usr/include/fltk\nCXXFLAGS  += -I/usr/include/fltk\nLDFLAGS += -L/usr/" libdir "/fltk/\n\n"; seen="1"} print}' Makefile || die "gawk patching failed."
	# Remove owner settings from install -lines.
	gawk -i inplace '{if ($1 == "install") gsub(/[[:space:]]-o[[:space:]][^[:space:]]+/,""); print}' Makefile || die "gawk patching failed."
	einfo "Makefile patching done."
	if [ "$PATCH_VERS" ]
	then
		einfo "Adding custom version number."
		awk -i inplace -v "cvers=$PATCH_VERS" '{if (/^\s*#define\s+EUREKA_VERSION\s+/) {sub("\"$","",$3); $3=$3 "-" cvers "\""} print}' ./src/main.h
	fi
}

#src_compile() {
#	emake FLTK_PREFIX="/usr/include/fltk"
#}

src_install() {

	if [ "$EGIT_COMMIT" ]
	then
		echo "$EGIT_COMMIT" > VERSION.nfo
	else
		#git describe --tags > VERSION.nfo
		git rev-parse HEAD >> VERSION.nfo
	fi

	[ -f VERSION.nfo ] && echo "rev $(git rev-list --count HEAD || echo -n "-")" >> VERSION.nfo && dodoc VERSION.nfo

	doicon -s 32 misc/eureka.xpm
	domenu misc/eureka.desktop

	usr="${D}/usr"
	mkdir -p "${usr}/share/eureka"
	mkdir -p "${usr}/bin"
	emake INSTALL_DIR="${usr}/share/eureka" install
	install-sums
}
