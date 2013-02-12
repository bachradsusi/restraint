
GTESTER ?= gtester
CC = gcc
CFLAGS ?= -O -g

PACKAGES = glib-2.0 libxml-2.0
CFLAGS += -Wall -std=c99 $(shell pkg-config --cflags $(PACKAGES))
ifeq ($(STATIC),1)
    LIBS = -Wl,-Bstatic $(shell pkg-config --libs $(PACKAGES)) -Wl,-Bdynamic -pthread -lrt
else
    LIBS = $(shell pkg-config --libs $(PACKAGES))
endif

hello: hello.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

TEST_PROGS =
test_%: test_%.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

TEST_PROGS += test_fetch_task
test_fetch_task: fetch_task.o
test_fetch_task.o: fetch_task.h

.PHONY: check
check: $(TEST_PROGS)
	MALLOC_CHECK_=2 \
	G_DEBUG="fatal_warnings fatal_criticals" \
	G_SLICE="debug-blocks" \
	$(GTESTER) --verbose $^

.PHONY: clean
clean:
	rm -f $(TEST_PROGS) *.o