<?php

declare(strict_types=1);

/*
 * What PHPStan is told TransformersPHP looks like, and only as much of it as
 * `Sluis\Onnx\Transformers` calls. The library itself needs FFI and so is not
 * installed in the workspace; without this the analysis of the one class that
 * talks to it would be a list of unknown names. Nothing loads this file at run
 * time. It is copied from codewithkyrian/transformers 0.6 and is checked against
 * it when the constraint in packages/onnx/composer.json moves.
 */

namespace Codewithkyrian\Transformers {
    class Transformers
    {
        public static function setup(): static
        {
            return new static;
        }

        public function setCacheDir(string $cacheDir): static
        {
            return $this;
        }

        public static function apply(): void {}
    }
}

namespace Codewithkyrian\Transformers\Pipelines {
    class Pipeline
    {
        /**
         * @param  string[]|string  $inputs
         * @return array<mixed>|object
         */
        public function __invoke(array|string $inputs, mixed ...$args): array|object
        {
            return [];
        }
    }

    function pipeline(string $task, ?string $modelName = null, bool $quantized = true): Pipeline
    {
        return new Pipeline;
    }
}
