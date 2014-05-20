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

P=libxslt
P_V=${P}-${LIBXSLT_VERSION}
PKG_TYPE=".tar.gz"
PKG_SRC_FILE="${P_V}${PKG_TYPE}"
PKG_URL=(
	"ftp://xmlsoft.org/libxslt/${PKG_SRC_FILE}"
)
PKG_DEPENDS=("libxml2")

src_download() {
	func_download
}

src_unpack() {
	func_uncompress
}

src_patch() {
	local _patches=(
		$P/libxslt-1.1.26-w64.patch
		$P/libxslt-1.1.27-disable_static_modules.patch
		$P/libxslt-1.1.28-win32-shared.patch
		$P/libxslt.m4-libxslt-1.1.26.patch
		$P/0002-python-linking-on.mingw.patch
		$P/0003-fix-concurrent-directory-creation.all.patch
		$P/0004-add-missing-include-for-python.all.patch
		$P/0005-fix-freelocales-export.all.patch
		$P/0006-no-undefined-tests.patch
		$P/0007-use-mingw-C99-compatible-functions-{v}snprintf.patch
	)
	
	func_apply_patches \
		_patches[@]
}

src_configure() {

	[[ ! -f $UNPACK_DIR/$P_V/pre-configure.marker ]] && {
		pushd $UNPACK_DIR/$P_V > /dev/null
		echo -n "---> Execute before configure..."
		libtoolize --copy --force > execute.log 2>&1
		aclocal >> execute.log 2>&1
		automake --add-missing >> execute.log 2>&1
		autoconf >> execute.log 2>&1
		echo " done"
		touch pre-configure.marker
		popd > /dev/null
	}
	
	local _conf_flags=(
		--prefix=${PREFIX}
		--build=${HOST}
		--host=${HOST}
		--target=${HOST}
		${LNKDEPS}
		--without-python
		--with-crypto
		--with-plugins
		--with-libxml-prefix=${PREFIX}
		CFLAGS="\"${HOST_CFLAGS}\""
		LDFLAGS="\"${HOST_LDFLAGS}\""
		CPPFLAGS="\"${HOST_CPPFLAGS}\""
	)
	local _allconf="${_conf_flags[@]}"
	export lt_cv_deplibs_check_method='pass_all'
	func_configure "$_allconf"
}

pkg_build() {
	local _make_flags=(
		${MAKE_OPTS}
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		"$_allmake" \
		"building..." \
		"built"
}

pkg_install() {
	local _install_flags=(
		${MAKE_OPTS}
		install
	)
	local _allinstall="${_install_flags[@]}"
	func_make \
		"$_allinstall" \
		"installing..." \
		"installed"
}
