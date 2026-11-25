"""Compara perfiles de generación con Ollama real y casos fijados del laboratorio."""

import argparse
from hashlib import sha256
import json
from pathlib import Path
from tempfile import TemporaryDirectory
from time import perf_counter

import httpx
from fastapi.testclient import TestClient

from scaa_backend.main import create_app
from scaa_backend.routine_generation import GeneratedRoutine
from scaa_backend.settings import Settings


class EmptyArasaac:
    def search(self, query):
        return []


def digest(value):
    return sha256(value.encode("utf-8")).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("lab_directory", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--candidate-only", action="store_true")
    args = parser.parse_args()
    lab = args.lab_directory
    output = args.output
    reserved = json.loads((lab / 'data/semantic-holdout.json').read_text())
    references = {
        "water-bottle": "generation-7090039f3739.json",
        "library-return": "generation-af5b8258d8db.json",
        "tidy-desk": "generation-8e2906cdd183.json",
    }
    server = 'http://127.0.0.1:11434'
    candidate = 'qwen3:4b-instruct'
    baseline = 'qwen2.5:1.5b'
    report = []
    with httpx.Client(base_url=server, trust_env=False, timeout=60) as ollama:
        tags = {m['name']: m for m in ollama.get('/api/tags').json()['models']}
        version = ollama.get('/api/version').json()['version']
        for model in (candidate,) if args.candidate_only else (baseline, candidate):
            with TemporaryDirectory() as tmp:
                profile = 'alternate' if model == candidate else 'baseline'
                app = create_app(Settings('test', Path(tmp), ollama_model=model, ollama_prompt_profile=profile))
                app.state.arasaac = EmptyArasaac()
                with TestClient(app) as api:
                    for case in reserved:
                        capture = {}
                        captured_calls = []
                        def instrument(request):
                            native = json.loads(request.content)
                            captured_calls.append(native)
                            start = perf_counter()
                            result = ollama.send(request)
                            capture['inference_seconds'] = round(perf_counter() - start, 4)
                            capture['ollama_status'] = result.status_code
                            body = result.json()
                            capture['load_duration_ns'] = body.get('load_duration')
                            capture['total_duration_ns'] = body.get('total_duration')
                            capture['done_reason'] = body.get('done_reason')
                            capture['ollama_reply'] = body.get('message', {}).get('content')
                            return result
                        app.state.generator.transport = httpx.MockTransport(instrument)
                        reference_id = references[case['id']]
                        reference = json.loads((lab / 'runs' / reference_id).read_text())
                        assert api.put('/api/v1/profile', json={'alias':'Perfil sintético', **case['context']}).status_code == 200
                        result = api.post('/api/v1/routines/proposals', json={'description': f"  {case['description']}  "})
                        assert len(captured_calls) == 1
                        sent = captured_calls[0]
                        user = json.loads(sent['messages'][1]['content'])
                        assert user['description'] == case['description'] and user['context'] == reference['context_sent']
                        assert sent['format'] == GeneratedRoutine.model_json_schema()
                        assert api.get('/api/v1/routines').json() == [] and api.get('/api/v1/pictograms').json() == []
                        lab_equal = None
                        output_equal = None
                        if model == candidate:
                            lab_equal = (
                                sent['model'] == reference['configuration']['model']
                                and tags[model]['digest'] == reference['model']['digest']
                                and sent['stream'] is False
                                and sent['options'] == {'temperature': reference['configuration']['temperature'],
                                                       'num_predict': reference['configuration']['num_predict']}
                                and sent['messages'][0]['content'] == reference['configuration']['prompt']
                                and 'think' not in sent and reference['configuration']['think'] is None
                                and 'seed' not in sent['options'] and reference['configuration']['seed'] is None
                                and app.state.generator.timeout == reference['configuration']['timeout']
                            )
                            assert lab_equal
                            if result.status_code == 200:
                                output_equal = (
                                    GeneratedRoutine.model_validate_json(capture['ollama_reply']).model_dump()
                                    == reference['interpreted']
                                )
                        report.append({
                            'case': case['id'], 'request': user, 'model': model, 'prompt_profile': profile, 'model_digest': tags[model]['digest'],
                            'quantization': tags[model]['details']['quantization_level'], 'prompt_sha256': digest(sent['messages'][0]['content']),
                            'options': sent['options'], 'request_timeout_seconds': app.state.generator.timeout,
                            'think_explicit': 'think' in sent, 'inference_count': len(captured_calls),
                            'api_status': result.status_code, 'proposal_persisted': False, 'reference_record': reference_id,
                            'candidate_configuration_matches_lab': lab_equal, 'candidate_output_matches_lab': output_equal, **capture,
                        })
                        output.write_text(json.dumps({'ollama_version': version, 'arasaac': 'adaptador controlado sin resultados',
                            'source': 'API del producto con SQLite temporal y transporte instrumentado hacia Ollama real',
                            'transport': 'observa y reenvía la solicitud de la API sin modificarla',
                            'schema_sha256': digest(json.dumps(sent['format'], sort_keys=True, ensure_ascii=False)),
                            'results':report}, ensure_ascii=False, indent=2)+'\n')
                        print(model, case['id'], result.status_code, capture.get('inference_seconds'), output_equal, flush=True)


if __name__ == '__main__':
    main()
