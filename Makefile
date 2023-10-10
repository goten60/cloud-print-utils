RUNTIME ?= python3.8
TEST_FILENAME ?= report.pdf
DOCKER_RUN = docker run --rm --platform linux/arm64

.PHONY: stack.deploy.weasyprint clean test.weasyprint

all: build/weasyprint-layer-$(RUNTIME).zip build/wkhtmltopdf-layer.zip

build/xmlsec-layer-$(RUNTIME).zip: xmlsec/layer_builder.sh \
    | _build
	${DOCKER_RUN} \
	    -v `pwd`/xmlsec:/out \
	    -t public.ecr.aws/sam/build-${RUNTIME}:latest \
	    bash /out/layer_builder.sh
	mv -f ./xmlsec/layer.zip ./build/xmlsec-no-fonts-layer.zip
	cd build && rm -rf ./opt && mkdir opt \
	    && unzip fonts-layer.zip -d opt \
	    && unzip xmlsec-no-fonts-layer.zip -d opt \
	    && cd opt && zip -r9 ../xmlsec-layer-${RUNTIME}.zip .

build/weasyprint-layer-$(RUNTIME).zip: weasyprint/layer_builder.sh \
    build/fonts-layer.zip \
    | _build
	${DOCKER_RUN} \
	    -v `pwd`/weasyprint:/out \
	    -t public.ecr.aws/sam/build-${RUNTIME}:latest \
	    bash /out/layer_builder.sh
	mv -f ./weasyprint/layer.zip ./build/weasyprint-no-fonts-layer.zip
	cd build && rm -rf ./opt && mkdir opt \
	    && unzip fonts-layer.zip -d opt \
	    && unzip weasyprint-no-fonts-layer.zip -d opt \
	    && cd opt && zip -r9 ../weasyprint-layer-${RUNTIME}.zip .

build/pandas-layer-$(RUNTIME).zip: pandas/layer_builder.sh \
    | _build
	${DOCKER_RUN} \
	    -v `pwd`/pandas:/out \
	    -t public.ecr.aws/sam/build-${RUNTIME}:latest \
	    bash /out/layer_builder.sh
	mv -f ./pandas/layer.zip ./build/pandas-no-fonts-layer.zip
	cd build && rm -rf ./opt && mkdir opt \
	    && unzip fonts-layer.zip -d opt \
	    && unzip pandas-no-fonts-layer.zip -d opt \
	    && cd opt && zip -r9 ../pandas-layer-${RUNTIME}.zip .

build/fonts-layer.zip: fonts/layer_builder.sh | _build
	${DOCKER_RUN} \
	    -e INSTALL_MS_FONTS="${INSTALL_MS_FONTS}" \
	    -v `pwd`/fonts:/out \
	    -t public.ecr.aws/sam/build-${RUNTIME}:latest \
	    bash /out/layer_builder.sh
	mv -f ./fonts/layer.zip $@

stack.diff:
	cd cdk-stacks && npm install && npm run build
	cdk diff --app ./cdk-stacks/bin/app.js --stack PrintStack --parameters uploadBucketName=${BUCKET}

stack.deploy:
	cd cdk-stacks && npm install && npm run build
	cdk deploy --app ./cdk-stacks/bin/app.js --stack PrintStack --parameters uploadBucketName=${BUCKET}

test.weasyprint:
	${DOCKER_RUN} \
	    -e GDK_PIXBUF_MODULE_FILE="/opt/lib/loaders.cache" \
	    -e FONTCONFIG_PATH="/opt/fonts" \
	    -e XDG_DATA_DIRS="/opt/lib" \
	    -v `pwd`/weasyprint:/var/task \
	    -v `pwd`/build/opt:/opt \
	    lambci/lambda:${RUNTIME} \
	    lambda_function.lambda_handler \
	    '{"url": "https://weasyprint.org/samples/report/report.html", "filename": "${TEST_FILENAME}", "return": "base64"}' \
	    | tail -1 | jq .body | tr -d '"' | base64 -d > ${TEST_FILENAME}
	@echo "Check ./${TEST_FILENAME}, eg.: xdg-open ${TEST_FILENAME}"


build/wkhtmltox-layer.zip: wkhtmltox/layer_builder.sh \
    build/fonts-layer.zip \
    | _build
	${DOCKER_RUN} \
	    -v `pwd`/wkhtmltox:/out \
	    -t public.ecr.aws/sam/build-${RUNTIME}:latest \
	    bash /out/layer_builder.sh
	mv -f ./wkhtmltox/layer.zip ./build/wkhtmltox-no-fonts-layer.zip
	cd build && rm -rf ./opt && mkdir opt \
	    && unzip fonts-layer.zip -d opt \
	    && unzip wkhtmltox-no-fonts-layer.zip -d opt \
	    && cd opt && zip -r9 ../wkhtmltox-layer.zip .

build/wkhtmltopdf-layer.zip: build/wkhtmltox-layer.zip
	cp build/wkhtmltox-layer.zip $@
	zip -d $@ "bin/wkhtmltoimage"

build/wkhtmltoimage-layer.zip: build/wkhtmltox-layer.zip
	cp build/wkhtmltox-layer.zip $@
	zip -d $@ "bin/wkhtmltopdf"

test.wkhtmltox:
	${DOCKER_RUN} \
	    -e FONTCONFIG_PATH="/opt/fonts" \
	    -v `pwd`/wkhtmltox:/var/task \
	    -v `pwd`/build/opt:/opt \
	    lambci/lambda:${RUNTIME} \
	    lambda_function.lambda_handler \
	    '{"args": "https://google.com", "filename": "${TEST_FILENAME}", "return": "base64"}' \
	    | tail -1 | jq .body | tr -d '"' | base64 -d > ${TEST_FILENAME}
	@echo "Check ./${TEST_FILENAME}, eg.: xdg-open ${TEST_FILENAME}"


_build:
	@mkdir -p build

clean:
	rm -rf ./build

fonts.list:
	${DOCKER_RUN} public.ecr.aws/sam/build-${RUNTIME}:latest \
	    bash -c "yum search font | grep noarch | grep -v texlive"
