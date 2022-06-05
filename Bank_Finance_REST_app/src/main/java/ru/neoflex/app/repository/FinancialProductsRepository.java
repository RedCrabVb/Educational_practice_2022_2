package ru.neoflex.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.neoflex.app.domain.FinancialProducts;

public interface FinancialProductsRepository extends JpaRepository<FinancialProducts, Long> {
}
