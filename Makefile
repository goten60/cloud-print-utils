RUNTIME ?= python3.11
TEST_FILENAME ?= report.pdf
DOCKER_RUN = docker run --rm --platform linux/x86_64 

.PHONY: clean 

all: build/weasyprint-layer-$(RUNTIME).zip build/wkhtmltopdf-layer.zip

build/xmlsec-layer-$(RUNTIME).zip: xmlsec/layer_builder.sh \
    | _build
	${DOCKER_RUN} \
	    -v `pwd`/xmlsec:/out \
	    -t public.ecr.aws/sam/build-${RUNTIME}:latest \
	    bash /out/layer_builder.sh
	mv -f ./xmlsec/layer.zip ./build/xmlsec-layer-${RUNTIME}.zip

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

_build:
	@mkdir -p build

clean:
	rm -rf ./build

fonts.list:
	${DOCKER_RUN} public.ecr.aws/sam/build-${RUNTIME}:latest \
	    bash -c "yum search font | grep noarch | grep -v texlive"
