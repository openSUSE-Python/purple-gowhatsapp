$(warning This Makefile exists for reference purposes. It is not maintained. Use CMake instead.)


export GO_FLAGS ?=
export CFLAGS ?=
export PLUGIN_VERSION := $(shell cat VERSION 2>/dev/null)
export CGO_CFLAGS := -DPLUGIN_VERSION=$(PLUGIN_VERSION) $(CFLAGS) $(shell pkg-config --cflags glib-2.0 purple opusfile gdk-pixbuf-2.0 2>/dev/null)
export CGO_LDFLAGS := $(shell pkg-config --libs glib-2.0 purple opusfile gdk-pixbuf-2.0 2>/dev/null)

GO_FILES := bridge.go constants.go groups.go handle_message.go handler.go logger.go login.go mark_read.go message_cache.go opusreader.go presence.go profile.go send_file_checks.go send_file.go send_message.go
C_FILES_GLUE := glue/blist.c glue/bridge.c glue/commands.c glue/display_message.c glue/groups.c glue/handle_attachment.c glue/init.c glue/login.c glue/options.c glue/pixbuf.c glue/presence.c glue/process_message.c glue/qrcode.c glue/receipt.c glue/send_file.c glue/send_message.c
C_FILES_BASE := bridge.c constants.c opusreader.c

all: libwhatsmeow.so

go.mod: go.mod.in
	cp go.mod.in go.mod

go.sum: go.mod
	go mod tidy

libwhatsmeow.a libwhatsmeow.h: go.mod go.sum $(GO_FILES) $(C_FILES_BASE) bridge.h constants.h opusreader.h # Reduced Go file list
	go build -buildmode=c-archive -o libwhatsmeow.a $(GO_FLAGS)

libwhatsmeow.so: libwhatsmeow.a libwhatsmeow.h constants.c $(C_FILES_GLUE) glue/gowhatsapp.h glue/pixbuf.h glue/purple_compat.h
	$(CC) -shared -fPIC -o libwhatsmeow.so $(C_FILES_GLUE) -I. libwhatsmeow.a $(CGO_CFLAGS) $(CGO_LDFLAGS)

clean:
	rm -f libwhatsmeow.a libwhatsmeow.h
	rm -f libwhatsmeow.so
