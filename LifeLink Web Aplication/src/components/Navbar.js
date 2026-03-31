import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import './Navbar.css';

const Navbar = () => {
  const location = useLocation();
  const isLandingPage = location.pathname === '/';

  const handleScrollToSection = (e, sectionId) => {
    e.preventDefault();
    const element = document.querySelector(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  };

  return (
    <nav className="navbar">
      <div className="navbar-container">
        <Link to="/" className="navbar-logo">
          <div className="logo-icon">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" fill="currentColor"/>
            </svg>
          </div>
          <span className="logo-text">LifeLink</span>
        </Link>

        {isLandingPage && (
          <div className="navbar-menu">
            <a 
              href="#about" 
              className="navbar-link"
              onClick={(e) => handleScrollToSection(e, '#about')}
            >
              About Us
            </a>
            <a 
              href="#mission" 
              className="navbar-link"
              onClick={(e) => handleScrollToSection(e, '#mission')}
            >
              Mission
            </a>
            <Link to="/login" className="navbar-link">Login</Link>
            <Link to="/join" className="navbar-btn">Register</Link>
          </div>
        )}

        {!isLandingPage && (
          <div className="navbar-menu">
            <Link to="/" className="navbar-link">
              <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor" style={{marginRight: '8px'}}>
                <path d="M8 0L0 6v10h6v-6h4v6h6V6L8 0z"/>
              </svg>
              Back to Home
            </Link>
          </div>
        )}
      </div>
    </nav>
  );
};

export default Navbar;