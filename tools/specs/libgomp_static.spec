# This spec file is read by gcc when linking.  It is used to specify the
# standard libraries we need in order to link with libgomp_static.
*link_gomp_static: -lgomp_static -static-libgcc -ldl
