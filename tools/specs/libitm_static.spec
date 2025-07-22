# This spec file is read by gcc when linking. It is used to specify the
# standard libraries we need in order to link with -fstatic-gnu-tm
*link_itm_static: -litm_static -static-libgcc -ldl
