!(import! &self motivation/registry)
!(import! &self motivation/state)
!(import! &self motivation/signals)
!(import! &self motivation/dynamics)
!(import! &self motivation/policy)
!(import! &self motivation/bridge)

!(import! &self (library lib_import))
!(git-import! "https://github.com/asi-alliance/OmegaClaw-Core.git")
!(import! &self (library OmegaClaw-Core lib_omegaclaw))

!(motivatedOmegaclaw)
