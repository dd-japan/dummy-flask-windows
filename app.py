"""
Datadog APM Test Application
A simple Flask application for testing Datadog APM features including:
- Error tracking
- Latency testing
- Custom spans and traces
"""

import os
import time
import random
import logging
from flask import Flask, render_template_string, jsonify, request

# Initialize Datadog APM tracer
from ddtrace import tracer, patch_all
patch_all()

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# HTML template for the web interface
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Datadog APM Test Application</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 900px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        h1 {
            color: #632CA6;
            text-align: center;
        }
        .card {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin: 15px 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .card h2 {
            margin-top: 0;
            color: #333;
        }
        button {
            background-color: #632CA6;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            margin: 5px;
        }
        button:hover {
            background-color: #774DBF;
        }
        button.error {
            background-color: #dc3545;
        }
        button.error:hover {
            background-color: #c82333;
        }
        button.warning {
            background-color: #ffc107;
            color: #333;
        }
        .result {
            margin-top: 15px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 4px;
            font-family: monospace;
            white-space: pre-wrap;
        }
        .status {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 4px;
            font-weight: bold;
        }
        .status.success { background-color: #d4edda; color: #155724; }
        .status.error { background-color: #f8d7da; color: #721c24; }
        .status.warning { background-color: #fff3cd; color: #856404; }
        input[type="number"] {
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
            width: 80px;
            margin: 0 10px;
        }
    </style>
</head>
<body>
    <h1>🐕 Datadog APM Test Application</h1>
    
    <div class="card">
        <h2>🏠 Health Check</h2>
        <p>Verify the application is running correctly.</p>
        <button onclick="testEndpoint('/health')">Check Health</button>
        <div id="health-result" class="result" style="display:none;"></div>
    </div>

    <div class="card">
        <h2>⏱️ Latency Testing</h2>
        <p>Test different response times to observe latency in APM.</p>
        <button onclick="testEndpoint('/latency/fast')">Fast (100ms)</button>
        <button onclick="testEndpoint('/latency/medium')">Medium (500ms)</button>
        <button onclick="testEndpoint('/latency/slow')">Slow (2s)</button>
        <button class="warning" onclick="testEndpoint('/latency/very-slow')">Very Slow (5s)</button>
        <br><br>
        <label>Custom delay (ms): <input type="number" id="custom-delay" value="1000" min="0" max="30000"></label>
        <button onclick="testCustomLatency()">Test Custom</button>
        <div id="latency-result" class="result" style="display:none;"></div>
    </div>

    <div class="card">
        <h2>❌ Error Testing</h2>
        <p>Generate different types of errors to test error tracking.</p>
        <button class="error" onclick="testEndpoint('/error/500')">500 Internal Error</button>
        <button class="error" onclick="testEndpoint('/error/404')">404 Not Found</button>
        <button class="error" onclick="testEndpoint('/error/400')">400 Bad Request</button>
        <button class="error" onclick="testEndpoint('/error/exception')">Unhandled Exception</button>
        <button class="error" onclick="testEndpoint('/error/random')">Random Error (50%)</button>
        <div id="error-result" class="result" style="display:none;"></div>
    </div>

    <div class="card">
        <h2>🔗 Nested Spans Testing</h2>
        <p>Test nested operations to observe trace hierarchy.</p>
        <button onclick="testEndpoint('/nested/simple')">Simple Nested</button>
        <button onclick="testEndpoint('/nested/complex')">Complex Nested</button>
        <button onclick="testEndpoint('/nested/database')">Simulated DB Calls</button>
        <div id="nested-result" class="result" style="display:none;"></div>
    </div>

    <div class="card">
        <h2>📊 Load Testing</h2>
        <p>Generate multiple requests to test APM under load.</p>
        <label>Number of requests: <input type="number" id="load-count" value="10" min="1" max="100"></label>
        <button onclick="runLoadTest()">Run Load Test</button>
        <div id="load-result" class="result" style="display:none;"></div>
    </div>

    <script>
        async function testEndpoint(endpoint) {
            const resultDivId = endpoint.includes('health') ? 'health-result' :
                               endpoint.includes('latency') ? 'latency-result' :
                               endpoint.includes('error') ? 'error-result' :
                               'nested-result';
            const resultDiv = document.getElementById(resultDivId);
            resultDiv.style.display = 'block';
            resultDiv.innerHTML = 'Loading...';
            
            const startTime = Date.now();
            try {
                const response = await fetch(endpoint);
                const elapsed = Date.now() - startTime;
                const data = await response.json();
                const statusClass = response.ok ? 'success' : 'error';
                resultDiv.innerHTML = `<span class="status ${statusClass}">Status: ${response.status}</span>
Response Time: ${elapsed}ms
${JSON.stringify(data, null, 2)}`;
            } catch (error) {
                resultDiv.innerHTML = `<span class="status error">Error</span>
${error.message}`;
            }
        }

        function testCustomLatency() {
            const delay = document.getElementById('custom-delay').value;
            testEndpoint(`/latency/custom?delay=${delay}`);
        }

        async function runLoadTest() {
            const count = parseInt(document.getElementById('load-count').value);
            const resultDiv = document.getElementById('load-result');
            resultDiv.style.display = 'block';
            resultDiv.innerHTML = `Running ${count} requests...`;
            
            const results = { success: 0, error: 0, totalTime: 0 };
            const startTime = Date.now();
            
            const promises = [];
            for (let i = 0; i < count; i++) {
                promises.push(
                    fetch('/latency/fast')
                        .then(r => { if (r.ok) results.success++; else results.error++; })
                        .catch(() => results.error++)
                );
            }
            
            await Promise.all(promises);
            results.totalTime = Date.now() - startTime;
            
            resultDiv.innerHTML = `<span class="status success">Load Test Complete</span>
Total Requests: ${count}
Successful: ${results.success}
Failed: ${results.error}
Total Time: ${results.totalTime}ms
Avg Time per Request: ${(results.totalTime / count).toFixed(2)}ms`;
        }
    </script>
</body>
</html>
"""


@app.route('/')
def index():
    """Main page with test interface."""
    return render_template_string(HTML_TEMPLATE)


@app.route('/health')
def health():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'service': 'datadog-apm-test',
        'version': '1.0.0',
        'timestamp': time.time()
    })


# ============================================
# Latency Testing Endpoints
# ============================================

@app.route('/latency/fast')
def latency_fast():
    """Fast response (~100ms)."""
    with tracer.trace('latency.fast', service='apm-test'):
        time.sleep(0.1)
        return jsonify({'type': 'fast', 'delay_ms': 100, 'message': 'Fast response'})


@app.route('/latency/medium')
def latency_medium():
    """Medium response (~500ms)."""
    with tracer.trace('latency.medium', service='apm-test'):
        time.sleep(0.5)
        return jsonify({'type': 'medium', 'delay_ms': 500, 'message': 'Medium response'})


@app.route('/latency/slow')
def latency_slow():
    """Slow response (~2s)."""
    with tracer.trace('latency.slow', service='apm-test'):
        time.sleep(2)
        return jsonify({'type': 'slow', 'delay_ms': 2000, 'message': 'Slow response'})


@app.route('/latency/very-slow')
def latency_very_slow():
    """Very slow response (~5s)."""
    with tracer.trace('latency.very_slow', service='apm-test'):
        time.sleep(5)
        return jsonify({'type': 'very_slow', 'delay_ms': 5000, 'message': 'Very slow response'})


@app.route('/latency/custom')
def latency_custom():
    """Custom delay response."""
    delay_ms = request.args.get('delay', 1000, type=int)
    delay_ms = min(max(delay_ms, 0), 30000)  # Clamp between 0 and 30s
    
    with tracer.trace('latency.custom', service='apm-test') as span:
        span.set_tag('delay_ms', delay_ms)
        time.sleep(delay_ms / 1000)
        return jsonify({'type': 'custom', 'delay_ms': delay_ms, 'message': f'Custom delay of {delay_ms}ms'})


# ============================================
# Error Testing Endpoints
# ============================================

@app.route('/error/500')
def error_500():
    """Generate a 500 Internal Server Error."""
    logger.error("Intentional 500 error triggered for APM testing")
    return jsonify({'error': 'Internal Server Error', 'code': 500, 'message': 'This is a test error'}), 500


@app.route('/error/404')
def error_404():
    """Generate a 404 Not Found Error."""
    logger.warning("Intentional 404 error triggered for APM testing")
    return jsonify({'error': 'Not Found', 'code': 404, 'message': 'Resource not found (test)'}), 404


@app.route('/error/400')
def error_400():
    """Generate a 400 Bad Request Error."""
    logger.warning("Intentional 400 error triggered for APM testing")
    return jsonify({'error': 'Bad Request', 'code': 400, 'message': 'Invalid request (test)'}), 400


@app.route('/error/exception')
def error_exception():
    """Generate an unhandled exception."""
    logger.error("Intentional exception triggered for APM testing")
    raise ValueError("This is an intentional unhandled exception for APM testing")


@app.route('/error/random')
def error_random():
    """50% chance of error."""
    with tracer.trace('error.random', service='apm-test') as span:
        if random.random() < 0.5:
            span.set_tag('error', True)
            logger.error("Random error occurred (50% chance)")
            return jsonify({'error': 'Random Error', 'code': 500, 'message': 'Bad luck! (50% chance error)'}), 500
        return jsonify({'status': 'success', 'message': 'Lucky! No error this time'})


# ============================================
# Nested Spans Testing
# ============================================

@app.route('/nested/simple')
def nested_simple():
    """Simple nested spans."""
    with tracer.trace('nested.parent', service='apm-test') as parent:
        time.sleep(0.05)
        
        with tracer.trace('nested.child1', service='apm-test'):
            time.sleep(0.1)
        
        with tracer.trace('nested.child2', service='apm-test'):
            time.sleep(0.1)
        
        parent.set_tag('children_count', 2)
    
    return jsonify({'type': 'simple_nested', 'spans': ['parent', 'child1', 'child2']})


@app.route('/nested/complex')
def nested_complex():
    """Complex nested spans with multiple levels."""
    with tracer.trace('nested.level1', service='apm-test'):
        time.sleep(0.05)
        
        with tracer.trace('nested.level2a', service='apm-test'):
            time.sleep(0.05)
            
            with tracer.trace('nested.level3', service='apm-test'):
                time.sleep(0.1)
        
        with tracer.trace('nested.level2b', service='apm-test'):
            time.sleep(0.1)
    
    return jsonify({
        'type': 'complex_nested',
        'structure': {
            'level1': {
                'level2a': {'level3': {}},
                'level2b': {}
            }
        }
    })


@app.route('/nested/database')
def nested_database():
    """Simulate database operations with spans."""
    results = []
    
    with tracer.trace('database.transaction', service='apm-test', resource='transaction') as txn:
        # Simulate connection
        with tracer.trace('database.connect', service='apm-test-db', resource='connect'):
            time.sleep(0.05)
            results.append('connected')
        
        # Simulate queries
        for i in range(3):
            with tracer.trace('database.query', service='apm-test-db', resource=f'SELECT * FROM table_{i}') as query:
                query.set_tag('query_id', i)
                time.sleep(random.uniform(0.05, 0.2))
                results.append(f'query_{i}')
        
        # Simulate commit
        with tracer.trace('database.commit', service='apm-test-db', resource='commit'):
            time.sleep(0.03)
            results.append('committed')
        
        txn.set_tag('query_count', 3)
    
    return jsonify({'type': 'database_simulation', 'operations': results})


# Error handler for unhandled exceptions
@app.errorhandler(Exception)
def handle_exception(e):
    logger.exception("Unhandled exception occurred")
    return jsonify({
        'error': 'Internal Server Error',
        'code': 500,
        'message': str(e),
        'type': type(e).__name__
    }), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    host = os.environ.get('HOST', '0.0.0.0')
    
    print(f"""
    ╔═══════════════════════════════════════════════════════════╗
    ║         Datadog APM Test Application                       ║
    ║                                                            ║
    ║   Running on: http://{host}:{port}                          
    ║                                                            ║
    ║   Endpoints:                                               ║
    ║   - /health           Health check                         ║
    ║   - /latency/*        Latency testing                      ║
    ║   - /error/*          Error testing                        ║
    ║   - /nested/*         Nested spans testing                 ║
    ╚═══════════════════════════════════════════════════════════╝
    """)
    
    app.run(host=host, port=port, debug=False)
