#include "lc3_bridge.h"

#include "lc3.h"

int lc3_bridge_frame_samples(int dt_us, int sr_hz) {
    return lc3_frame_samples(dt_us, sr_hz);
}

int lc3_bridge_frame_bytes(int dt_us, int bitrate) {
    return lc3_frame_bytes(dt_us, bitrate);
}

int lc3_bridge_resolve_bitrate(int dt_us, int nbytes) {
    return lc3_resolve_bitrate(dt_us, nbytes);
}

unsigned lc3_bridge_decoder_size(int dt_us, int sr_hz) {
    return lc3_decoder_size(dt_us, sr_hz);
}

lc3_bridge_decoder_t lc3_bridge_setup_decoder(
    int dt_us,
    int sr_hz,
    int sr_pcm_hz,
    void *mem
) {
    return (lc3_bridge_decoder_t)lc3_setup_decoder(dt_us, sr_hz, sr_pcm_hz, mem);
}

int lc3_bridge_decode_s16(
    lc3_bridge_decoder_t decoder,
    const void *in,
    int nbytes,
    int16_t *pcm,
    int stride
) {
    return lc3_decode((lc3_decoder_t)decoder, in, nbytes, LC3_PCM_FORMAT_S16, pcm, stride);
}

lc3_bridge_decoder_t lc3_bridge_reset_decoder(
    int dt_us,
    int sr_hz,
    int sr_pcm_hz,
    void *mem
) {
    return (lc3_bridge_decoder_t)lc3_setup_decoder(dt_us, sr_hz, sr_pcm_hz, mem);
}
