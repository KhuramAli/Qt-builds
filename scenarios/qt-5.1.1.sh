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

P=qt
P_V=qt-everywhere-opensource-src-${QT_VERSION}
EXT=".tar.xz"
SRC_FILE="${P_V}${EXT}"
URL=http://download.qt-project.org/official_releases/qt/5.1/${QT_VERSION}/single/$SRC_FILE
DEPENDS=(gperf icu fontconfig freetype libxml2 libxslt pcre perl ruby)

change_paths() {
	local _sql_include=
	local _sql_lib=
	[[ $STATIC_DEPS == no ]] && {
		_sql_include="$QTDIR/databases/firebird/include:$QTDIR/databases/mysql/include/mysql:$QTDIR/databases/pgsql/include:$QTDIR/databases/oci/include"
		_sql_lib="$QTDIR/databases/firebird/lib:$QTDIR/databases/mysql/lib:$QTDIR/databases/pgsql/lib:$QTDIR/databases/oci/lib"
	}
	export INCLUDE="$MINGWHOME/$HOST/include:$PREFIX/include:$PREFIX/include/libxml2:${_sql_include}"
	export LIB="$MINGWHOME/$HOST/lib:$PREFIX/lib:${_sql_lib}"
	export CPATH="$MINGWHOME/$HOST/include:$PREFIX/include:$PREFIX/include/libxml2:${_sql_include}"
	export LIBRARY_PATH="$MINGWHOME/$HOST/lib:$PREFIX/lib:${_sql_lib}"
	OLD_PATH=$PATH
	export PATH=$BUILD_DIR/$P-$QT_VERSION/qtbase/bin:$BUILD_DIR/$P-$QT_VERSION/qtbase/lib:$MINGW_PART_PATH:$MSYS_PART_PATH:$WINDOWS_PART_PATH
	#$BUILD_DIR/$P-$QT_VERSION/gnuwin32/bin:
}

restore_paths() {
	unset INCLUDE
	unset LIB
	unset CPATH
	unset LIBRARY_PATH
	export PATH=$OLD_PATH
	unset OLD_PATH
}

src_download() {
	func_download $P_V $EXT $URL
}

src_unpack() {
	func_uncompress $P_V $EXT
}

src_patch() {
	local _patches=(
		$P/5.0.x/qt-5.0.0-use-fbclient-instead-of-gds32.patch
		$P/5.0.x/qt-5.0.0-oracle-driver-prompt.patch
		$P/5.1.x/qt-5.1.0-win32-g++-mkspec-optimization.patch
		#$P/5.1.x/qt-5.1.x-fix-configure-tests.patch
		$P/5.1.x/qt-5.1.x-syncqt-fix.patch
		$P/5.1.x/qt-5.1.x-win_flex-replace.patch
		$P/5.1.x/qt-5.1.1-fix-mingw-file_id_128.patch
		$P/5.1.x/qt-5.1.1-fix-mingw-SHSTOCKICONINFO.patch
		#$P/5.1.x/qt-5.1.x-workaround-pkgconfig-install-issue.patch
	)

	func_apply_patches \
		$P_V \
		_patches[@]

	touch $UNPACK_DIR/$P_V/qtbase/.gitignore
}

src_configure() {

	if [[ ! -d ${QTDIR}/databases && $STATIC_DEPS == no ]]
	then
		mkdir -p ${QTDIR}/databases
		cp -rf ${PATCH_DIR}/${P}/databases-${ARCHITECTURE}/* ${QTDIR}/databases/
	fi

	lndirs $P_V $P-$QT_VERSION

	pushd $BUILD_DIR/$P-$QT_VERSION/qtbase/mkspecs/win32-g++ > /dev/null
		if [ -f qmake.conf.patched ]
		then
			rm -f qmake.conf
			cp -f qmake.conf.patched qmake.conf
		else
			cp -f qmake.conf qmake.conf.patched
		fi

		cat qmake.conf | sed 's|%OPTIMIZE_OPT%|'"$OPTIM"'|g' \
					| sed 's|%STATICFLAGS%|'"$STATIC_LD"'|g' > qmake.conf.tmp
		rm -f qmake.conf
		mv qmake.conf.tmp qmake.conf
	popd > /dev/null

	if [ -f $BUILD_DIR/$P-$QT_VERSION/configure.marker ]
	then
		echo "--> configured"
	else
		pushd $BUILD_DIR/$P-$QT_VERSION > /dev/null
		echo -n "--> configure..."
		local _opengl
		[[ $USE_OPENGL_DESKTOP == yes ]] && {
			_opengl="-opengl desktop"
		} || {
			_opengl="-angle"
		}
	
		change_paths
		local _mode=shared
		[[ $STATIC_DEPS == yes ]] && {
			_mode=static
		}
		local _conf_flags=(
			-prefix $QTDIR_WIN
			-opensource
			-$_mode
			-confirm-license
			-debug-and-release
			$( [[ $STATIC_DEPS == no ]] \
				&& echo "-plugin-sql-ibase \
						 -plugin-sql-mysql \
						 -plugin-sql-psql \
						 -plugin-sql-oci \
						 -plugin-sql-odbc \
						 -no-iconv \
						 -icu \
						 -system-pcre \
						 -system-zlib" \
				|| echo "-no-icu \
						 -no-iconv \
						 -qt-sql-sqlite \
						 -qt-zlib \
						 -qt-pcre" \
			)
			-fontconfig
			-openssl
			-no-dbus
			$_opengl
			-platform win32-g++
			-nomake tests
			-nomake examples
		)
		local _allconf="${_conf_flags[@]}"
		./configure.bat \
			$_allconf \
			> ${LOG_DIR}/${P_V}_configure.log 2>&1 || die "Qt configure error"
	
		restore_paths
		echo " done"
		touch configure.marker
		popd > /dev/null
	fi
}

pkg_build() {
	change_paths
	[[ $USE_OPENGL_DESKTOP == no ]] && {
		# Workaround for
		# https://bugreports.qt-project.org/browse/QTBUG-28845
		pushd $BUILD_DIR/$P-$QT_VERSION/qtbase/src/angle/src/libGLESv2 > /dev/null
		if [ -f workaround.marker ]
		then
			echo "--> Workaround applied"
		else
			echo -n "--> Applying workaround..."
			qmake libGLESv2.pro
			cat Makefile.Debug | grep fxc.exe | cmd > workaround.log 2>&1
			echo " done"
			touch workaround.marker
		fi
		popd > /dev/null
	} 
	
	local _make_flags=(
		${MAKE_OPTS}
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		$P-$QT_VERSION \
		"mingw32-make" \
		"$_allmake" \
		"building..." \
		"built"

	restore_paths
}

pkg_install() {
	change_paths
	
	local _install_flags=(
		${MAKE_OPTS}
		install
	)
	local _allinstall="${_install_flags[@]}"
	func_make \
		$P-$QT_VERSION \
		"mingw32-make" \
		"$_allinstall" \
		"installing..." \
		"installed"

	install_docs

	# Workaround for build other components (qbs, qtcreator, etc)
	if [[ ! -f $BUILD_DIR/$P-$QT_VERSION/qwindows.marker && $STATIC_DEPS == yes ]]
	then
		cp -f ${QTDIR}/plugins/platforms/libqwindows.a ${QTDIR}/lib/
		cp -f ${QTDIR}/plugins/platforms/libqwindowsd.a ${QTDIR}/lib/
		touch $BUILD_DIR/$P-$QT_VERSION/qwindows.marker
	fi

	# Workaround for installing empty .pc files
	[[ ! -f $BUILD_DIR/$P-$QT_VERSION/pkgconfig.marker ]] && {
		local _pc_files=( $(find $BUILD_DIR/$P-$QT_VERSION -type f -name Qt5*.pc) )
		cp -f ${_pc_files[@]} ${QTDIR}/lib/pkgconfig/ > /dev/null 2>&1
		touch $BUILD_DIR/$P-$QT_VERSION/pkgconfig.marker
	}
	restore_paths
}

install_docs() {

	local _make_flags=(
		${MAKE_OPTS}
		docs
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		$P-$QT_VERSION \
		"mingw32-make" \
		"$_allmake" \
		"building docs..." \
		"built-docs"

	_make_flags=(
		${MAKE_OPTS}
		install_qch_docs
	)
	_allmake="${_make_flags[@]}"
	func_make \
		$P-$QT_VERSION \
		"mingw32-make" \
		"$_allmake" \
		"installing docs..." \
		"installed-docs"
}