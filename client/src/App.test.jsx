import { render, screen, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import '@testing-library/jest-dom'
import App from './App'

describe('App Component', () => {

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('renders ShopSmart title and default products', async () => {

    global.fetch = vi.fn(() =>
      Promise.resolve({
        json: () =>
          Promise.resolve({
            status: 'ok',
            message: 'ShopSmart Backend is running',
            timestamp: 'now'
          })
      })
    )

    render(<App />)

    // Check header (using getAllByText because 'ShopSmart' text exists in both header and footer)
    expect(screen.getAllByText(/ShopSmart/i)[0]).toBeInTheDocument()
    
    // Check product renders
    expect(screen.getByText(/Wireless Headphones/i)).toBeInTheDocument()

    // Wait for async API status update to finish
    await waitFor(() => {
      expect(screen.getByText(/API Online/i)).toBeInTheDocument()
    })
  })

  it('renders offline data after failed fetch', async () => {

    global.fetch = vi.fn(() => Promise.reject(new Error('Network Error')))

    render(<App />)

    expect(await screen.findByText(/API Offline/i)).toBeInTheDocument()
  })
})
