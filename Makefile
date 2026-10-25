CC = clang
CFLAGS = -fobjc-arc -Wall -O2
FRAMEWORKS = -framework Cocoa
LIBS = -lsqlite3

APP_NAME = AITouchBar
APP_BUNDLE = $(APP_NAME).app
MACOS_DIR = $(APP_BUNDLE)/Contents/MacOS
RESOURCES_DIR = $(APP_BUNDLE)/Contents/Resources
PLIST_NAME = com.antigravity.AITouchBar.plist
LAUNCH_AGENTS_DIR = $(HOME)/Library/LaunchAgents

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

install-autostart: build
	@mkdir -p $(LAUNCH_AGENTS_DIR)
	@echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" >> $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "<plist version=\"1.0\">" >> $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "<dict>" >> $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "    <key>Label</key>" >> $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "    <string>com.antigravity.AITouchBar</string>" >> $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "    <key>ProgramArguments</key>" >> $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "    <array>" >> $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "        <string>$(PWD)/$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)</string>" >> $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "    </array>" >> $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "    <key>RunAtLoad</key>" >> $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "    <true/>" >> $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "</dict>" >> $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "</plist>" >> $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@launchctl unload $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME) 2>/dev/null || true
	@launchctl load $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "==> Autostart instalado em $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)"
	@echo "==> O AITouchBar agora iniciará automaticamente com o macOS e sincronizará com a abertura/fechamento do Antigravity!"

uninstall-autostart:
	@launchctl unload $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME) 2>/dev/null || true
	@rm -f $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "==> Autostart removido com sucesso."

clean:
	rm -rf *.o $(APP_NAME) $(APP_BUNDLE)
