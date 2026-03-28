#ifndef LC3_BRIDGE_H
#define LC3_BRIDGE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void *lc3_bridge_decoder_t;

int lc3_bridge_frame_samples(int dt_us, int sr_hz);
int lc3_bridge_frame_bytes(int dt_us, int bitrate);
int lc3_bridge_resolve_bitrate(int dt_us, int nbytes);

unsigned lc3_bridge_decoder_size(int dt_us, int sr_hz);

lc3_bridge_decoder_t lc3_bridge_setup_decoder(
    int dt_us,
    int sr_hz,
    int sr_pcm_hz,
    void *mem
);

int lc3_bridge_decode_s16(
    lc3_bridge_decoder_t decoder,
    const void *in,
    int nbytes,
    int16_t *pcm,
    int stride
);

lc3_bridge_decoder_t lc3_bridge_reset_decoder(
    int dt_us,
    int sr_hz,
    int sr_pcm_hz,
    void *mem
);

#ifdef __cplusplus
}
#endif

#endif
