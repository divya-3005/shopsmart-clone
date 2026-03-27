import { useState, useEffect } from 'react'

// Dummy product data
const PRODUCTS = [
    { id: 1, name: 'Wireless Headphones', price: 99.99, icon: '🎧' },
    { id: 2, name: 'Smart Watch', price: 149.00, icon: '⌚' },
    { id: 3, name: 'Laptop Backpack', price: 45.50, icon: '🎒' },
    { id: 4, name: 'Mechanical Keyboard', price: 120.00, icon: '⌨️' },
    { id: 5, name: 'Gaming Mouse', price: 59.99, icon: '🖱️' },
    { id: 6, name: 'Bluetooth Speaker', price: 79.99, icon: '🔊' },
];

function App() {
    const [data, setData] = useState(null);
    const [cartCount, setCartCount] = useState(0);

    // API Integration: Fetching Backend Health Status
    useEffect(() => {
        const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:5001';
        fetch(`${apiUrl}/api/health`)
            .then(res => res.json())
            .then(data => setData(data))
            .catch(err => {
                console.error('Error fetching health check:', err);
                setData({ status: 'error', message: 'Backend is offline' });
            });
    }, []);

    const addToCart = () => {
        setCartCount(prev => prev + 1);
    };

    return (
        <div className="app-container">
            {/* Header Component */}
            <header className="header">
                <h1>🛍️ ShopSmart</h1>
                <button className="cart-button">
                    🛒 Cart ({cartCount})
                </button>
            </header>

            {/* Main Content Component */}
            <main className="main-content">
                <h2>Featured Products</h2>
                <div className="products-grid">
                    {PRODUCTS.map(product => (
                        <div key={product.id} className="product-card">
                            <div className="product-image">
                                {product.icon}
                            </div>
                            <div className="product-info">
                                <h3 className="product-title">{product.name}</h3>
                                <div className="product-price">${product.price.toFixed(2)}</div>
                                <button className="add-to-cart-btn" onClick={addToCart}>
                                    Add to Cart
                                </button>
                            </div>
                        </div>
                    ))}
                </div>
            </main>

            {/* Footer Component with API Integration Info */}
            <footer className="footer">
                <p>&copy; {new Date().getFullYear()} ShopSmart Inc.</p>
                <div className={`status-badge ${data?.status === 'ok' ? 'status-online' : 'status-offline'}`}>
                    <div className={`status-dot ${data?.status === 'ok' ? 'online' : 'offline'}`}></div>
                    {data?.status === 'ok' ? 'API Online' : 'API Offline'}
                </div>
            </footer>
        </div>
    )
}

export default App
