package ru.neoflex.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.neoflex.app.domain.StatusFinancialProducts;

public interface StatusFinancialProductsRepository extends JpaRepository<StatusFinancialProducts, Long> {
}
