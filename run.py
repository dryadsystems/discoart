import time
import logging
from typing import Any
from pqueue import Maestro, Prompt, Result
import discoart


class DiscoMaestro(Maestro):
    def handle_item(self, generator: Any, prompt: Prompt) -> tuple[Any, Result]:
        "finagle settings, generate it depending on settings, make a video if appropriate"
        start_time = time.time()
        image = discoart.create(
            text_prompts=prompt.prompt,
            n_batches=1,
            diffusion_sampling_mode="plms",
            width_height=[512, 512],
            cutn_batches=2,
            **prompt.param_dict,
        )
        logging.info(image)
        image.save(f"output/{prompt.prompt_id}.png")
        return generator, Result(
            elapsed=round(time.time() - start_time),
            filepath=f"output/{prompt.prompt_id}.png",
            loss=-1,
            seed=result[0].tags["seed"],
        )


if __name__ == "__main__":
    DiscoMaestro().main()
