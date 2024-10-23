#######################################################################
# Create an extensible SoapUI mock service runner image using Debian-slim
#######################################################################

# Use the openjdk 11 slim base image
FROM openjdk:11-jre-slim

LABEL fbascheper <temp01@fam-scheper.nl>

##########################################################
# Download and unpack soapui 5.7.2
##########################################################

RUN groupadd -r -g 1000 soapui && useradd -r -u 1000 -g soapui -m -d /home/soapui soapui

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        gosu && \
    rm -rf /var/lib/apt/lists/*

RUN curl -kLO https://dl.eviware.com/soapuios/5.7.2/SoapUI-5.7.2-linux-bin.tar.gz && \
    echo "0cffcbee929bd2abb484f7ab0e8ad495 SoapUI-5.7.2-linux-bin.tar.gz" >> MD5SUM && \
    md5sum -c MD5SUM && \
    tar -xzf SoapUI-5.7.2-linux-bin.tar.gz -C /home/soapui && \
    rm -f SoapUI-5.7.2-linux-bin.tar.gz MD5SUM

RUN chown -R soapui:soapui /home/soapui && \
    find /home/soapui -type d -execdir chmod 770 {} \; && \
    find /home/soapui -type f -execdir chmod 660 {} \;

############################################
# Setup MockService runner
############################################

USER soapui
ENV HOME /home/soapui
ENV SOAPUI_DIR /home/soapui/SoapUI-5.7.2
ENV SOAPUI_PRJ /home/soapui/soapui-prj

############################################
# Add customization sub-directories (for entrypoint)
############################################
ADD docker-entrypoint-initdb.d  /docker-entrypoint-initdb.d
ADD soapui-prj                  $SOAPUI_PRJ

############################################
# Expose ports and start SoapUI mock service
############################################
USER root

EXPOSE 8991

COPY docker-entrypoint.sh /
RUN chmod 700 /docker-entrypoint.sh && \
    chmod 770 $SOAPUI_DIR/bin/*.sh && \
    chown -R soapui:soapui $SOAPUI_PRJ && \
    find $SOAPUI_PRJ -type d -execdir chmod 770 {} \; && \
    find $SOAPUI_PRJ -type f -execdir chmod 660 {} \;

############################################
# Start SoapUI mock service runner
############################################

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["start-soapui"]