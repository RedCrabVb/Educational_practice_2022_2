import { Link, useNavigate } from 'react-router-dom'
import { Button, Navbar, NavDropdown, Nav, Container } from 'react-bootstrap'
import { USER } from '../../utils/Storage'

export const Header = () => {
    return (
        <Navbar bg="light" expand="lg">
            <Container>
                <Navbar.Brand as={Link} to="/">Главная</Navbar.Brand>
                <Navbar.Toggle aria-controls="basic-navbar-nav" />
                <Navbar.Collapse id="basic-navbar-nav">
                    <Nav className="me-auto">
                        <Nav.Link as={Link} to="/note/all">Заметки</Nav.Link>
                        <Nav.Link as={Link} to="/task/all">Задачи</Nav.Link>
                    </Nav>
                </Navbar.Collapse>
                <div className="col-md-3 text-end">
                    <Link className="btn btn-outline-primary me-2" onClick={() =>  localStorage.removeItem(USER)}  to={'/login'}>Войти</Link>
                    <Link className="btn btn-primary" to={'/login'}>Выйти</Link>
                </div>
            </Container>
        </Navbar>
    )
} 