# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: git-r3-verify.eclass
# @MAINTAINER:
# zucca
# @AUTHOR:
# zucca
# @BLURB: git-r3 with sha512 verification
# @DESCRIPTION:
# Inherits git-r3 automatically and performs sha512 checksumming of retrieved files.

EXPORT_FUNCTIONS src_prepare src_install

#inherit git-r3

# @FUNCTION: create-sums
# @USAGE: <new.sha512sum.bz2> [directory]
# @DESCRIPTION:
# Creates bzip2 compressed list of sha512sums from files
# inside current directory or inside the provided directory.
# This includes all the subdirectories as well.
create-sums() {
	[ -z "$1" ] && die "create-sums: Not enough arguments."
	find ${2:="./"} -type f -not -regex '.*/\.git/.*' -not -name '*.sha512' -not -name '.git*' -exec sha512sum {} + \
		| tee >(bzip2 -z9c > "${1}") \
		| cut -d ' ' -f 2- \
		| while read line
		do
			einfo "$line"
		done || die "create-sums failed."
	unset line
	return 0
}

# @FUNCTION: verify-git-sources
# @USAGE: <sha512sum.bz2 -file>
# @DESCRIPTION:
# Verifies files with sha512.
verify-git-sources() {
	[ -z "$1" ] && die "verify-git-sources: Missing input .sha512.bz2 "
	[ -f "$1" ] && die "verify-git-sources: '$1' - no such file or isn't a file."
	bzcat "$1" | sha512sum -c || die "sha512 verification FAILED!"
	einfo "Checksums match."
	return 0
}

# @FUNCTION: install-sums
# @USAGE: [.sha512.bz2]
# @DESCRIPTION:
# A little helper function which tries to locate
# SUM_FILE and if succeeds then installs it using 'doins'.
# Note that if SUM_FILE is already set, then this function
# has very little use. :)
install-sums() {
	if use create-sums
	then
		[ -z "$1" ] || SUM_FILE="$1"
		# Looks complicated at first...
		if [ -f "${SUM_FILE:="${T%/}/${EGIT_COMMIT:="$(git rev-parse HEAD)"}.sha512.bz2"}" ]
		then
			doins "${SUM_FILE}"
		else
			ewarn "Couldn't find checksum file to install."
			ewarn "Skipping it therefore..."
		fi
	fi
}

# @FUNCTION: git-r3-verify_src_prepare
# @USAGE: none
# @DESCRIPTION:
# Default src_prepare function.
# Verifies source files aginst the sha512sums or creates sha512sums if the package is live.
# USE flags 'verify-git-sources' and 'create-sums' can be used to toggle this behaviour.
git-r3-verify_src_prepare() {
	SUM_FILE="${T%/}/${EGIT_COMMIT:="$(git rev-parse HEAD)"}.sha512.bz2"
	case "$PV" in
		9999*)
			if use create-sums
			then
				create-sums "$SUM_FILE"
			    use verify-git-sources && verify-git-sources "$SUM_FILE"
			fi
		;;
		*)
			if use verify-git-sources
			then
				verify-git-sources "${FILESDIR%/}/${SUM_FILE##*/}"
			else
				ewarn "Source checksum verification SKIPPED!"
			fi
		;;
	esac

	default
}

# @FUNCTION: git-r3-verify_src_install
# @USAGE: none
# @DESCRIPTION:
# Default src_install function.
# Does normal install but also installs checksum file if found.
git-r3-verify_src_install() {
	default
	install-sums
}
