import { Link, useNavigate } from 'react-router-dom'
import { Button, Navbar, NavDropdown, Nav, Container } from 'react-bootstrap'
import { USER } from '../../utils/Storage'
import { api } from '../../utils/Api'
import { route } from '../../utils/ScreenNames'

export const Header = () => {

    const requestOptions: RequestInit = {
        method: 'POST',
        // headers: new Headers({ }),
        credentials: 'include',
    }

    function logout() {
        localStorage.removeItem(USER)
        fetch(api.logout, requestOptions)
            .then(d => { console.log({ logout: d }); return d.status })
    }

    return (
        <Navbar bg="light" expand="lg">
            <Container>
                <Navbar.Brand as={Link} to="/">Главная</Navbar.Brand>
                <Navbar.Toggle aria-controls="basic-navbar-nav" />
                <Navbar.Collapse id="basic-navbar-nav">
                    <Nav className="me-auto">
                        <Nav.Link as={Link} to={route.finacialProducts}>Финансовые продукты</Nav.Link>
                        <Nav.Link as={Link} to={route.transactions}>Транзакции</Nav.Link>
                    </Nav>
                </Navbar.Collapse>
                <div className="col-md-3 text-end">
                    <Link className="btn btn-outline-primary me-2" to={'/login'}>Войти</Link>
                    <Link className="btn btn-primary" onClick={() => logout()} to={'/login'}>Выйти</Link>
                </div>
            </Container>
        </Navbar>
    )
} 