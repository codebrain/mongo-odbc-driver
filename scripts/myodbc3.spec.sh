# Copyright (c) 2000, 2013, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston
# MA  02110-1301  USA.

##############################################################################
#
# mysql-connector-odbc @CONNECTOR_BASE_VERSION@ RPM specification
#
##############################################################################

%global mysql_vendor	Oracle and/or its affiliates

%if 0%{?commercial}
%global license_type	Commercial
%global license_files	LICENSE.mysql
%global product_suffix	-commercial
%else
%global license_type	GPLv2
%global license_files	COPYING
%endif

# Use rpmbuild -ba --define 'shared_mysqlclient 1' ... to build shared
%{!?shared_mysqlclient: %global static_mysqlclient 1}

##############################################################################
#
#  Main information section
#
##############################################################################

Summary:	An ODBC @CONNECTOR_BASE_VERSION@ driver for MySQL - driver package
Name:		mysql-connector-odbc%{?product_suffix}
Version:	@CONNECTOR_NODASH_VERSION@
Release:	1%{?dist}
License:	Copyright (c) 2000, @CURRENT_YEAR@, %{mysql_vendor}. All rights reserved.  Under %{license_type} license as shown in the Description field.
Source0:	http://cdn.mysql.com/Downloads/Connector-ODBC/@CONNECTOR_BASE_VERSION@/%{name}-@CONNECTOR_VERSION@-src.tar.gz
URL:		http://www.mysql.com/
Group:		Applications/Databases
Vendor:		%{mysql_vendor}
Packager:	%{mysql_vendor} Product Engineering Team <mysql-build@oss.oracle.com>
BuildRequires:	cmake 
%{?shared_mysqlclient:BuildRequires: mysql-community-devel}
BuildRequires:	unixODBC-devel
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

%if 0%{odbc_gui}
%package setup
Summary:	An ODBC @CONNECTOR_BASE_VERSION@ driver for MySQL - setup library
Group:		Application/Databases
Requires:	%{name} = %{version}-%{release}
%endif

##############################################################################
#
#  Documentation
#
##############################################################################

%description
mysql-connector-odbc is an ODBC (3.50) level 0 (with level 1 and level
2 features) driver for connecting an ODBC-aware application to MySQL.
mysql-connector-odbc  works on Windows NT/2000/XP/2003, and most Unix
platforms (incl. OSX and Linux). MySQL is a trademark of
%{mysql_vendor}

mysql-connector-odbc @CONNECTOR_BASE_VERSION@ is an enhanced version of MyODBC 2.50 to meet
ODBC 3.5 specification. The driver is commonly referred to as
'MySQL ODBC @CONNECTOR_BASE_VERSION@ Driver'.

The MySQL software has Dual Licensing, which means you can use the
MySQL software free of charge under the GNU General Public License
(http://www.gnu.org/licenses/). You can also purchase commercial MySQL
licenses from %{mysql_vendor} if you do not wish to be bound by the
terms of the GPL. See the chapter "Licensing and Support" in the
manual for further info.

The MySQL web site (http://www.mysql.com/) provides the latest news
and information about the MySQL software. Also please see the
documentation and the manual for more information.

%if 0%{?odbc_gui}
%description setup
The setup library for the MySQL ODBC package, handles the optional GUI
dialog for configuring the driver.
%endif

##############################################################################
#
#  Build
#
##############################################################################

%prep
%setup -q -n %{name}-@CONNECTOR_VERSION@-src

%build
mkdir release
pushd release
export CFLAGS="%{optflags}"
cmake -G "Unix Makefiles"   \
    -DRPM_BUILD=1           \
    -DCMAKE_INSTALL_PREFIX=%{_prefix} \
%if 0%{?odbc_gui}
%else
    -DDISABLE_GUI=1         \
%endif
%if 0%{?unixodbc}
    -DWITH_UNIXODBC=1       \
%endif
    %{?cmake_opt_extra}      \
    ..

# Note that the ".." needs to be last, in case some arguments expands to 
# the empty string, and then "cmake" thinks is "current directory"

make  %{?_smp_mflags} VERBOSE=1
popd

##############################################################################
#
#  Cleanup
#
##############################################################################

%clean
rm -rf %{buildroot}

##############################################################################
#
#  Install and deinstall scripts
#
##############################################################################

# ----------------------------------------------------------------------
# Install, but remove the doc files.
# The way %doc <file-without-path> works, we can't
# have these files installed
# ----------------------------------------------------------------------

%install
pushd release
make DESTDIR=%{buildroot} install VERBOSE=1
rm -vf  %{buildroot}%{_prefix}/{ChangeLog,README*,LICENSE.*,COPYING,INSTALL*,Licenses_for_Third-Party_Components.txt}
rm -vfr %{buildroot}%{_prefix}/test
popd

# ----------------------------------------------------------------------
# REGISTER DRIVER
# Note that "-e" is not working for drivers currently, so we have to
# deinstall before reinstall to change anything
# ----------------------------------------------------------------------

%post 
if [ -x /usr/bin/myodbc-installer ]; then
    /usr/bin/myodbc-installer -a -d -n "MySQL ODBC @CONNECTOR_BASE_VERSION@ Driver" -t "DRIVER=%{_libdir}/libmyodbc5.so"
fi

%if 0%{?odbc_gui}
%post setup
/usr/bin/myodbc-installer -r -d -n "MySQL ODBC @CONNECTOR_BASE_VERSION@ Driver"
/usr/bin/myodbc-installer -a -d -n "MySQL ODBC @CONNECTOR_BASE_VERSION@ Driver" -t "DRIVER=%{_libdir}/libmyodbc5.so;SETUP=%{_libdir}/libmyodbc5S.so"
%endif

# ----------------------------------------------------------------------
# DEREGISTER DRIVER 
# ----------------------------------------------------------------------

# Removing the driver package, we simply orphan any related DSNs
%preun
myodbc-installer -r -d -n "MySQL ODBC @CONNECTOR_BASE_VERSION@ Driver"

# Removing the setup RPM, downgrade the registration
%if 0%{?odbc_gui}
%preun setup
if [ "$1" = 0 ]; then
    if [ -x %{_bindir}/myodbc-installer ]; then
        %{_bindir}/myodbc-installer -r -d -n "MySQL ODBC @CONNECTOR_BASE_VERSION@ Driver" > /dev/null 2>&1 || :
        %{_bindir}/myodbc-installer -a -d -n "MySQL ODBC @CONNECTOR_BASE_VERSION@ Driver" -t "DRIVER=%{_libdir}/libmyodbc5.so" > /dev/null 2>&1 || :
    fi
fi
%endif

##############################################################################
#
#  Listing of files to be in the package
#
##############################################################################

%files
%defattr(-, root, root, -)
%{_bindir}/myodbc-installer
%{_libdir}/libmyodbc5.so
%doc %{license_files}
%doc ChangeLog README README.debug INSTALL INSTALL.win Licenses_for_Third-Party_Components.txt

%if 0%{?odbc_gui}
%files setup
%defattr(-, root, root, -)
%{_libdir}/libmyodbc5S.so
%endif

##############################################################################
