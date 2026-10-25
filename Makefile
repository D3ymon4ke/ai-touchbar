CC = clang
CFLAGS = -fobjc-arc -Wall -O2
FRAMEWORKS = -framework Cocoa
LIBS = -lsqlite3

APP_NAME = AITouchBar
APP_BUNDLE = $(APP_NAME).app
MACOS_DIR = $(APP_BUNDLE)/Contents/MacOS
RESOURCES_DIR = $(APP_BUNDLE)/Contents/Resources

SRCS = main.m AppDelegate.m AIUsageData.m AIUsageReader.m TouchBarGaugeView.m TouchBarModalController.m
OBJS = $(SRCS:.m=.o)

all: build

%.o: %.m
	$(CC) $(CFLAGS) -c $< -o $@

$(APP_NAME): $(OBJS)
	$(CC) $(CFLAGS) $(FRAMEWORKS) $(LIBS) $(OBJS) -o $(APP_NAME)

build: $(APP_NAME)
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@cp $(APP_NAME) $(MACOS_DIR)/
	@cp Info.plist $(APP_BUNDLE)/Contents/
	@cp get_quota.py $(RESOURCES_DIR)/
	@chmod +x $(RESOURCES_DIR)/get_quota.py
	@codesign -s - --force $(APP_BUNDLE) 2>/dev/null || true
	@echo "==> Build finalizado com sucesso: $(APP_BUNDLE)"

run: build
	@pkill -f "$(APP_NAME)" 2>/dev/null || true
	@echo "==> Iniciando $(APP_BUNDLE) em segundo plano..."
	@open $(APP_BUNDLE)

stop:
	@pkill -f "$(APP_NAME)" 2>/dev/null && echo "==> $(APP_NAME) finalizado." || echo "==> $(APP_NAME) não está rodando."

clean:
	rm -rf *.o $(APP_NAME) $(APP_BUNDLE)
