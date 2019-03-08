# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# Forked from net-misc/youtube-dl-99999999::gentoo

EAPI="7"
PYTHON_COMPAT=(python{2_7,3_4,3_5,3_6})
inherit bash-completion-r1 distutils-r1 git-r3 readme.gentoo-r1

DESCRIPTION="youtube-dl with yle (Finnish broadcasting company) support"
HOMEPAGE="https://github.com/Hegezcc/youtube-dl"
EGIT_REPO_URI="$HOMEPAGE"
EGIT_BRANCH="yleareena"
LICENSE="public-domain"

KEYWORDS=""
RESTRICT="test"
SLOT="0"
RDEPEND="
	dev-python/setuptools[${PYTHON_USEDEP}]
"
DEPEND="
	${RDEPEND}
	!!net-misc/youtube-dl
"

MY_PN="${PN%-yle}"

src_compile() {
	distutils-r1_src_compile

	emake ${MY_PN}.{bash-completion,fish,zsh}
}

python_install_all() {
	dodoc README.md

	newbashcomp ${MY_PN}.bash-completion ${MY_PN}

	insinto /usr/share/zsh/site-functions
	newins ${MY_PN}.zsh _${MY_PN}

	insinto /usr/share/fish/vendor_completions.d
	doins ${MY_PN}.fish

	distutils-r1_python_install_all

	rm -r "${ED}"/usr/etc || die
	rm -r "${ED}"/usr/share/doc/youtube_dl || die
}

pkg_postinst() {
	elog "${MY_PN}(1) / https://bugs.gentoo.org/355661 /"
	elog "https://github.com/rg3/${MY_PN}/blob/master/README.md#faq :"
	elog
	elog "${MY_PN} works fine on its own on most sites. However, if you want"
	elog "to convert video/audio, you'll need avconf (media-video/libav) or"
	elog "ffmpeg (media-video/ffmpeg). On some sites - most notably YouTube -"
	elog "videos can be retrieved in a higher quality format without sound."
	elog "${MY_PN} will detect whether avconv/ffmpeg is present and"
	elog "automatically pick the best option."
	elog
	elog "Videos or video formats streamed via RTMP protocol can only be"
	elog "downloaded when rtmpdump (media-video/rtmpdump) is installed."
	elog "Downloading MMS and RTSP videos requires either mplayer"
	elog "(media-video/mplayer) or mpv (media-video/mpv) to be installed."
	elog
	elog "If you want ${MY_PN} to embed thumbnails from the metadata into the"
	elog "resulting MP4 files, consider installing media-video/atomicparsley"
}
