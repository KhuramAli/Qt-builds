#!/bin/bash

#
# The BSD 3-Clause License. http://www.opensource.org/licenses/BSD-3-Clause
#
# This file is part of 'Qt-builds' project.
# Copyright (c) 2013 by Alexpux (alexpux@gmail.com)
# All rights reserved.
#
# Project: Qt-builds ( https://github.com/Alexpux/Qt-builds )
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# - Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the distribution.
# - Neither the name of the 'Qt-builds' nor the names of its contributors may
#     be used to endorse or promote products derived from this software
#     without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# **************************************************************************

P=zlib
P_V=${P}-${ZLIB_VERSION}
EXT=".tar.gz"
SRC_FILE="${P_V}${EXT}"
URL=http://sourceforge.net/projects/libpng/files/zlib/${ZLIB_VERSION}/${SRC_FILE}
DEPENDS=()

src_download() {
	func_download $P_V $EXT $URL
}

src_unpack() {
	func_uncompress $P_V $EXT
}

src_patch() {
	local _patches=(
		$P/01-zlib-1.2.7-1-buildsys.mingw.patch
		$P/02-no-undefined.mingw.patch
		$P/03-dont-put-sodir-into-L.mingw.patch
		$P/04-wrong-w8-check.mingw.patch
		$P/05-fix-a-typo.mingw.patch
	)
	
	func_apply_patches \
		$P_V \
		_patches[@]
}

src_configure() {
	lndirs
	
	local _conf_flags=(
		--prefix=${PREFIX}
		--sharedlibdir="${PREFIX}/bin"
	)
	local _allconf="${_conf_flags[@]}"
	func_configure $P_V $P_V "$_allconf"
}

pkg_build() {
	local _make_flags=(
		${MAKE_OPTS}
		STRIP=true
		all
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		${P_V} \
		"/bin/make" \
		"$_allmake" \
		"building..." \
		"built"

	minizip_configure
	minizip_build

	[[ ! -f $BUILD_DIR/$P_V/pkgconfig.marker ]] && {
		pushd $BUILD_DIR/$P_V > /dev/null
		sed \
			-e 's|@prefix@|'${PREFIX}'|g' \
			-e 's|@exec_prefix@|${prefix}|g' \
			-e 's|@libdir@|${prefix}/lib|g' \
			-e 's|@sharedlibdir@|${prefix}/bin|g' \
			-e 's|@includedir@|${prefix}/include|g' \
			-e 's|@VERSION@|'${ZLIB_VERSION}'|g' \
			zlib.pc.in > zlib.pc || die "SED error"
		touch pkgconfig.marker
		popd > /dev/null
	}
}

pkg_install() {

	local _install_flags=(
		STRIP=true
		install
	)

	local _allinstall="${_install_flags[@]}"
	func_make \
		${P_V} \
		"/bin/make" \
		"$_allinstall" \
		"installing..." \
		"installed"

	minizip_install
	[[ ! -f $BUILD_DIR/$P_V/pkg_install.marker ]] && {
		cp -f $BUILD_DIR/$P_V/zlib.pc ${PREFIX}/lib/pkgconfig/
		[[ $STATIC_DEPS == no ]] && {
			rm -f ${PREFIX}/lib/libz.a
		}
		touch $BUILD_DIR/$P_V/pkg_install.marker
	}
}

minizip_configure() {
	[[ ! -f $BUILD_DIR/$P_V/minizip_reconf.marker ]] && {
		pushd $BUILD_DIR/$P_V/contrib/minizip > /dev/null
		autoreconf -fi > $BUILD_DIR/$P_V/autoreconf_minizip.log 2>&1 || die "Fail autoreconf minizip"
		popd > /dev/null
		touch $BUILD_DIR/$P_V/minizip_reconf.marker
	}
	local _conf_flags=(
		--prefix=${PREFIX}
		--host=${HOST}
		-enable-demos
		${LNKDEPS}
		CFLAGS="\"${HOST_CFLAGS} -DHAVE_BZIP2\""
		LDFLAGS="\"${HOST_LDFLAGS}\""
		CPPFLAGS="\"${HOST_CPPFLAGS}\""
		LIBS="\"-lbz2\""
	)
	local _allconf="${_conf_flags[@]}"
	func_configure $P_V/contrib/minizip contrib/minizip "$_allconf" $BUILD_DIR/$P_V
}

minizip_build() {
	local _make_flags=(
		-j1
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		${P_V}/contrib/minizip \
		"/bin/make" \
		"$_allmake" \
		"building..." \
		"built"
}

minizip_install() {
	local _install_flags=(
		${MAKE_OPTS}
		install
	)
	local _allinstall="${_install_flags[@]}"
	func_make \
		${P_V}/contrib/minizip \
		"/bin/make" \
		"$_allinstall" \
		"installing..." \
		"installed"
}